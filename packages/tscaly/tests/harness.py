#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# harness.py — what the runner and its readers share: the STORE, the two BATCH
# supervisors, the framing parsers and the verdict helpers.
#
# ★★★ WHY THERE IS A STORE AND NOT A TREE (2026-09-02). Until this file the runner
# wrote every artifact of every unit to its own file — ~24 per unit, 443 317 files
# for a stage-2 run — and the box's indexer and endpoint protection scanned each one
# (packages/tscaly/CLAUDE.md §0.5). Nothing in the COMPARISON ever needed a file:
# compare.py held both sides in memory and diffed them there. The files existed as
# the exchange format between the runner and its eight readers. That exchange format
# is now ONE SQLite file per run, `tests/out/run.db`, held open for the run
# (journal_mode OFF, so no side files either). Everything a reader used to open —
# the unit's text, `<art>.ours`, `<art>.ref`, `<art>.ref.cut`, `types.walk`,
# `types.diags`, the diff — is a column here, and `export-tree` writes the old
# layout on demand for the pre-2026-09-02 control batteries that still read it.
#
# ★★★ AND ONE PROCESS PER SIDE INSTEAD OF ONE PER (UNIT, ARTIFACT). `tscaly_dump
# --batch` and `oracle_batch` each take a whole corpus and answer it in one framed
# stream; `run_batch` and `run_oracle` below supervise them: a crash or a hang is
# blamed on the unit (or case) that was in progress — the framing has an END marker
# for exactly that — and the process is restarted on the remainder, so one bad unit
# costs one restart and never the run. Parallelism is `jobs` such processes over
# disjoint chunks, and it is the caller's, because the reference has process-wide
# state that its batch oracle resets per artifact (tests/oracle/batch.go).
#
# What did NOT change, and was measured byte for byte over the whole stage-1 tree
# before the tree was retired: every artifact body on both sides, `cut_fields`,
# the verdict rules, the counters and the failures list.

import os
import sqlite3
import subprocess
import sys
import threading
import time
import difflib

SUFFIXES = (".ts", ".mts", ".cts", ".tsx", ".jsx", ".js", ".cjs", ".mjs", ".json")

# (artifact, `cut -d' ' -f1-<keep>` width; 0 = no cut)
ARTIFACTS = (("tokens", 4), ("ast", 5), ("jsdoc", 5), ("symbols", 0), ("flow", 0),
             ("types", 0))
ART_NAMES = [a for a, _ in ARTIFACTS]

DUMP_SEPS = [b"==== TSCALY-DUMP ast\n", b"==== TSCALY-DUMP jsdoc\n",
             b"==== TSCALY-DUMP symbols\n", b"==== TSCALY-DUMP flow\n",
             b"==== TSCALY-DUMP types\n"]
SEP_DIAGS = b"==== TSCALY-SECTION diags\n"
SEP_DUMP = b"==== TSCALY-SECTION dump\n"
UNIT_HEAD = b"==== TSCALY-UNIT "
UNIT_END = b"==== TSCALY-END\n"

TIMED_OUT = 124          # the rc a killed-for-inactivity process is recorded with


# ───────────────────────── the small pure helpers ─────────────────────────

def cut_fields(data: bytes, keep: int) -> bytes:
    """Exactly `cut -d' ' -f1-keep`, on bytes — verified against BSD cut."""
    if not data:
        return data
    trailing_nl = data.endswith(b"\n")
    lines = data.split(b"\n")
    if trailing_nl:
        lines = lines[:-1]
    out = b"\n".join(b" ".join(line.split(b" ")[:keep]) for line in lines)
    return out + (b"\n" if trailing_nl else b"")


def classify_unit(unit_name: str):
    """None when the unit is compared, else the skip reason."""
    return None if unit_name.lower().endswith(SUFFIXES) else "other"


def kind_bucket(unit_name: str):
    low = unit_name.lower()
    if low.endswith((".js", ".cjs", ".mjs")):
        return "js"
    if low.endswith(".jsx"):
        return "jsx"
    if low.endswith(".tsx"):
        return "tsx"
    if low.endswith(".json"):
        return "json"
    return None


def load_accepted(path):
    accepted = set()
    if not os.path.isfile(path):
        return accepted
    with open(path, "r", errors="surrogateescape") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 3:
                accepted.add((parts[0], parts[1]))
    return accepted


def has_line_prefix(data: bytes, prefix: bytes) -> bool:
    return data.startswith(prefix) or (b"\n" + prefix) in data


def diff_lines(ref, ours, n=None):
    """diff(1)'s normal format for two line lists; the first line is the hunk head."""
    lines = []
    sm = difflib.SequenceMatcher(None, ref, ours, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        a = str(i1 + 1) if i2 - i1 == 1 else "%d,%d" % (i1 + 1, i2)
        b = str(j1 + 1) if j2 - j1 == 1 else "%d,%d" % (j1 + 1, j2)
        if tag == "replace":
            lines.append("%sc%s" % (a, b))
            lines += ["< " + x for x in ref[i1:i2]]
            lines.append("---")
            lines += ["> " + x for x in ours[j1:j2]]
        elif tag == "delete":
            lines.append("%sd%d" % (a, j1))
            lines += ["< " + x for x in ref[i1:i2]]
        else:
            lines.append("%da%s" % (i2, b))
            lines += ["> " + x for x in ours[j1:j2]]
        if n is not None and len(lines) >= n:
            break
    return lines if n is None else lines[:n]


def _text_lines(data: bytes):
    s = data.decode("utf-8", "surrogateescape")
    return s.split("\n")[:-1] if s.endswith("\n") else s.split("\n")


def diff_bytes(ref: bytes, ours: bytes) -> bytes:
    return ("\n".join(diff_lines(_text_lines(ref), _text_lines(ours))) + "\n").encode(
        "utf-8", "surrogateescape")


# ───────────────────────── framing ─────────────────────────

def write_units_file(path, units):
    """units: iterable of (unit path, content bytes) → the `--batch` input."""
    with open(path, "wb") as fh:
        for upath, content in units:
            fh.write(b"==== TSCALY-UNIT %d %s\n" % (len(content), upath.encode("utf-8", "surrogateescape")))
            fh.write(content)
            fh.write(b"\n")


def parse_dump_stream(blob: bytes):
    """→ (complete: {path: body}, in_progress: path or None) of a `--batch` answer."""
    complete = {}
    in_progress = None
    parts = blob.split(UNIT_HEAD)
    for part in parts[1:]:
        nl = part.find(b"\n")
        if nl < 0:
            in_progress = part.decode("utf-8", "surrogateescape")
            break
        path = part[:nl].decode("utf-8", "surrogateescape")
        body = part[nl + 1:]
        if body.endswith(UNIT_END):
            complete[path] = body[:-len(UNIT_END)]
        else:
            in_progress = path
            break
    return complete, in_progress


def split_dump(blob: bytes):
    """tscaly_dump's five sections → {art: bytes}, or None when malformed."""
    parts, rest = [], blob
    for sp in DUMP_SEPS:
        if sp not in rest:
            return None
        a, rest = rest.split(sp, 1)
        parts.append(a)
    parts.append(rest)
    return dict(zip(ART_NAMES, parts))


def split_types(blob: bytes):
    """the types section → (walk, diags, dump), or None when malformed."""
    if SEP_DIAGS not in blob or SEP_DUMP not in blob:
        return None
    walk, rest = blob.split(SEP_DIAGS, 1)
    diags, dump = rest.split(SEP_DUMP, 1)
    return walk, diags, dump


def parse_oracle_stream(blob: bytes):
    """oracle_batch's stream → (cases: [case dict], in_progress: case dict or None).

    case: {name, file, split_rc, split_err, units: [unit]}; unit: {idx, name, path,
    content, refs: {art: (rc, out, err)}}. The last case is `in_progress` when the
    stream ends inside it (a crash or a kill), and is NOT in `cases`.
    """
    pos = 0
    n = len(blob)
    cases = []
    cur = None

    def line():
        nonlocal pos
        e = blob.find(b"\n", pos)
        if e < 0:
            raise EOFError
        l = blob[pos:e]
        pos = e + 1
        return l

    def take(k):
        nonlocal pos
        if pos + k + 1 > n or blob[pos + k:pos + k + 1] != b"\n":
            raise EOFError
        b = blob[pos:pos + k]
        pos += k + 1
        return b

    try:
        while pos < n:
            l = line()
            if l.startswith(b"==== TSCALY-CASE "):
                if cur is not None:
                    cases.append(cur)
                name, cf = l[len(b"==== TSCALY-CASE "):].split(b"\t", 1)
                cur = {"name": name.decode("utf-8", "surrogateescape"),
                       "file": cf.decode("utf-8", "surrogateescape"),
                       "split_rc": None, "split_err": b"", "units": []}
            elif l.startswith(b"==== TSCALY-SPLIT "):
                rc, k = l.split()[2:]
                cur["split_rc"] = int(rc)
                cur["split_err"] = take(int(k))
            elif l.startswith(b"==== TSCALY-UNIT "):
                head, uname, upath = l.split(b"\t")
                _, _, idx, k = head.split()
                cur["units"].append({"idx": int(idx),
                                     "name": uname.decode("utf-8", "surrogateescape"),
                                     "path": upath.decode("utf-8", "surrogateescape"),
                                     "content": take(int(k)), "refs": {}})
            elif l.startswith(b"==== TSCALY-REF "):
                _, _, art, rc, no, ne = l.split()
                out = take(int(no))
                err = take(int(ne))
                cur["units"][-1]["refs"][art.decode()] = (int(rc), out, err)
            else:
                raise ValueError("oracle stream: unexpected line %r" % l[:80])
    except EOFError:
        return cases, cur
    # A case is complete only when its last unit carries all six answers.
    if cur is not None:
        if cur["split_rc"] is None or (cur["units"] and len(cur["units"][-1]["refs"]) < len(ART_NAMES)):
            return cases, cur
        cases.append(cur)
    return cases, None


# ───────────────────────── the supervised process ─────────────────────────

def stream_process(argv, stdin_bytes, timeout):
    """Run argv to the end, or kill it after `timeout` seconds WITHOUT OUTPUT.

    → (rc, stdout, stderr, timed_out). The timeout is inactivity, not total
    duration: a batch over 18 000 units legitimately runs for minutes, and what a
    hang looks like is a process that stops writing.
    """
    proc = subprocess.Popen(argv, stdin=subprocess.PIPE if stdin_bytes is not None else subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    chunks = {"out": [], "err": []}
    last = [time.time()]
    lock = threading.Lock()

    def reader(stream, key):
        while True:
            data = stream.read1(1 << 16) if hasattr(stream, "read1") else stream.read(1 << 16)
            if not data:
                return
            with lock:
                chunks[key].append(data)
                last[0] = time.time()

    threads = [threading.Thread(target=reader, args=(proc.stdout, "out"), daemon=True),
               threading.Thread(target=reader, args=(proc.stderr, "err"), daemon=True)]
    for t in threads:
        t.start()
    if stdin_bytes is not None:
        def feed():
            try:
                proc.stdin.write(stdin_bytes)
                proc.stdin.close()
            except (BrokenPipeError, OSError):
                pass
        threading.Thread(target=feed, daemon=True).start()
    timed_out = False
    while proc.poll() is None:
        time.sleep(0.05)
        with lock:
            idle = time.time() - last[0]
        if timeout and idle > timeout:
            proc.kill()
            timed_out = True
            break
    proc.wait()
    for t in threads:
        t.join()
    return proc.returncode, b"".join(chunks["out"]), b"".join(chunks["err"]), timed_out


def _chunks(items, k):
    k = max(1, min(k, len(items))) if items else 1
    n = len(items)
    return [items[i * n // k:(i + 1) * n // k] for i in range(k)] if items else []


def run_batch(binary, flag, units, scratch, jobs, timeout):
    """Our side: `binary [flag] --batch <units file>` over `units` [(path, content)],
    in `jobs` chunks. → {path: (rc, body, err)}; rc 0 = answered, TIMED_OUT = the
    process fell silent on this unit, anything else = it died on this unit."""
    os.makedirs(scratch, exist_ok=True)
    results = {}
    rlock = threading.Lock()

    def one_chunk(ci, pending):
        attempt = 0
        while pending:
            path = os.path.join(scratch, "units.%d.%d" % (ci, attempt))
            write_units_file(path, pending)
            argv = [binary] + ([flag] if flag else []) + ["--batch", path]
            rc, out, err, timed_out = stream_process(argv, None, timeout)
            try:
                os.unlink(path)
            except OSError:
                pass
            complete, in_progress = parse_dump_stream(out)
            with rlock:
                for p, body in complete.items():
                    results[p] = (0, body, b"")
            done = len(complete)
            if rc == 0 and not timed_out and in_progress is None and done == len(pending):
                return
            if in_progress is not None:
                blamed = in_progress
            elif done < len(pending):
                blamed = pending[done][0]        # died between two units: the next one
            else:
                return
            with rlock:
                results[blamed] = (TIMED_OUT if timed_out else (rc if rc else 1), b"", err[-4000:])
            pending = [u for u in pending if u[0] not in results]
            attempt += 1

    threads = [threading.Thread(target=one_chunk, args=(i, c)) for i, c in enumerate(_chunks(list(units), jobs))]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    return results


def run_oracle(binary, out_dir, selected, jobs, timeout):
    """The reference side: `oracle_batch <out dir>` fed `<case file>\\t<name>` lines,
    in `jobs` chunks. → {name: case dict} (see parse_oracle_stream). A case the
    process died or hung inside comes back with its finished units intact, every
    missing answer rc 3 with the cause in err, and the run continues after it."""
    results = {}
    rlock = threading.Lock()

    def one_chunk(pending):
        while pending:
            tsv = "".join("%s\t%s\n" % (cf, name) for cf, name in pending).encode("utf-8", "surrogateescape")
            rc, out, err, timed_out = stream_process([binary, out_dir], tsv, timeout)
            cases, in_progress = parse_oracle_stream(out)
            with rlock:
                for c in cases:
                    results[c["name"]] = c
            if rc == 0 and not timed_out and in_progress is None and len(cases) == len(pending):
                return
            cause = ("the reference process fell silent for %gs" % timeout) if timed_out \
                else "the reference process died (rc %s): %s" % (rc, err[-2000:].decode("utf-8", "replace").strip())
            if in_progress is not None:
                c = in_progress
            elif len(cases) < len(pending):
                cf, name = pending[len(cases)]
                c = {"name": name, "file": cf, "split_rc": None, "split_err": b"", "units": []}
            else:
                return
            if c["split_rc"] is None:
                c["split_rc"], c["split_err"] = 3, cause.encode()
            for u in c["units"]:
                for art in ART_NAMES:
                    if art not in u["refs"]:
                        u["refs"][art] = (3, b"", cause.encode())
            with rlock:
                results[c["name"]] = c
            pending = [(cf, name) for cf, name in pending if name not in results]

    threads = [threading.Thread(target=one_chunk, args=(c,)) for c in _chunks(list(selected), jobs)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    return results


# ───────────────────────── the store ─────────────────────────

SCHEMA = """
CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE cases(ci INTEGER PRIMARY KEY, name TEXT UNIQUE, case_file TEXT,
                   split_rc INTEGER, split_err BLOB);
CREATE TABLE units(ci INTEGER, idx INTEGER, name TEXT, path TEXT UNIQUE, key TEXT,
                   compared INTEGER, content BLOB, PRIMARY KEY(ci, idx));
CREATE TABLE artifacts(ci INTEGER, idx INTEGER, art TEXT,
                       ours_rc INTEGER, ours BLOB, ours_err BLOB,
                       ref_rc INTEGER, ref BLOB, ref_err BLOB, cut BLOB,
                       walk BLOB, diags BLOB, verdict TEXT, message TEXT, diff BLOB,
                       PRIMARY KEY(ci, idx, art));
"""


def store_path(out="packages/tscaly/tests/out"):
    return os.path.join(out, "run.db")


class Store:
    def __init__(self, path, create=False):
        self.path = path
        if create:
            for suffix in ("", "-journal", "-wal", "-shm"):
                try:
                    os.unlink(path + suffix)
                except OSError:
                    pass
        self.db = sqlite3.connect(path, check_same_thread=False)
        self.db.execute("PRAGMA journal_mode=OFF")
        self.db.execute("PRAGMA synchronous=OFF")
        self.lock = threading.Lock()
        if create:
            self.db.executescript(SCHEMA)

    @staticmethod
    def open(out="packages/tscaly/tests/out"):
        p = store_path(out)
        if not os.path.isfile(p):
            return None
        return Store(p)

    def commit(self):
        self.db.commit()

    def close(self):
        self.db.commit()
        self.db.close()

    # writes
    def put_meta(self, key, value):
        with self.lock:
            self.db.execute("INSERT OR REPLACE INTO meta VALUES (?, ?)", (key, str(value)))

    def put_case(self, ci, name, case_file, split_rc, split_err):
        with self.lock:
            self.db.execute("INSERT INTO cases VALUES (?,?,?,?,?)", (ci, name, case_file, split_rc, split_err))

    def put_unit(self, ci, idx, name, path, key, compared, content):
        with self.lock:
            self.db.execute("INSERT INTO units VALUES (?,?,?,?,?,?,?)", (ci, idx, name, path, key, int(compared), content))

    def put_ref(self, ci, idx, art, ref_rc, ref, ref_err):
        with self.lock:
            self.db.execute("INSERT INTO artifacts(ci, idx, art, ref_rc, ref, ref_err) VALUES (?,?,?,?,?,?)",
                            (ci, idx, art, ref_rc, ref, ref_err))

    def put_ours(self, ci, idx, art, ours_rc, ours, ours_err, walk=None, diags=None):
        with self.lock:
            self.db.execute("UPDATE artifacts SET ours_rc=?, ours=?, ours_err=?, walk=?, diags=? WHERE ci=? AND idx=? AND art=?",
                            (ours_rc, ours, ours_err, walk, diags, ci, idx, art))

    def put_verdict(self, ci, idx, art, verdict, message, cut, diff):
        with self.lock:
            self.db.execute("UPDATE artifacts SET verdict=?, message=?, cut=?, diff=? WHERE ci=? AND idx=? AND art=?",
                            (verdict, message, cut, diff, ci, idx, art))

    # reads
    def meta(self, key, default=None):
        row = self.db.execute("SELECT value FROM meta WHERE key=?", (key,)).fetchone()
        return row[0] if row else default

    def cases(self):
        return self.db.execute("SELECT ci, name, case_file, split_rc, split_err FROM cases ORDER BY ci").fetchall()

    def units(self, compared_only=True, filt=""):
        """→ [(ci, idx, case_name, key, unit_name, path, content)] in corpus order."""
        q = ("SELECT u.ci, u.idx, c.name, u.key, u.name, u.path, u.content FROM units u "
             "JOIN cases c ON c.ci = u.ci " + ("WHERE u.compared = 1 " if compared_only else "") +
             "ORDER BY u.ci, u.idx")
        rows = self.db.execute(q).fetchall()
        if filt:
            rows = [r for r in rows if filt in r[2]]
        return rows

    def artifact(self, ci, idx, art):
        """→ dict of every column, or None."""
        cur = self.db.execute("SELECT * FROM artifacts WHERE ci=? AND idx=? AND art=?", (ci, idx, art))
        row = cur.fetchone()
        if row is None:
            return None
        return dict(zip([d[0] for d in cur.description], row))

    def artifacts_of(self, art):
        """→ {(ci, idx): dict} for one artifact over the whole run."""
        cur = self.db.execute("SELECT * FROM artifacts WHERE art=?", (art,))
        names = [d[0] for d in cur.description]
        return {(r[0], r[1]): dict(zip(names, r)) for r in cur.fetchall()}

    def unit_by_key(self, key):
        return self.db.execute("SELECT ci, idx, key, name, path FROM units WHERE key=?", (key,)).fetchone()


# ───────────────────────── the command line ─────────────────────────

def _export_tree(store, root):
    """The pre-2026-09-02 layout, for the old control batteries: cases/<name>/units.manifest,
    units/uNN_<base>, <idx>/<art>.{ours,ref,ref.cut,diff} and types.{walk,diags}."""
    units_by_case = {}
    for ci, idx, cname, key, uname, path, content in store.units(compared_only=False):
        units_by_case.setdefault(ci, []).append((idx, cname, uname, path, content))
    n = 0
    for ci, name, case_file, split_rc, split_err in store.cases():
        cdir = os.path.join(root, "cases", name)
        os.makedirs(cdir, exist_ok=True)
        if split_rc:
            with open(os.path.join(cdir, "units.err"), "wb") as fh:
                fh.write(split_err or b"")
        with open(os.path.join(cdir, "units.manifest"), "w", encoding="utf-8", errors="surrogateescape") as man:
            for idx, cname, uname, path, content in units_by_case.get(ci, []):
                written = os.path.join(root, "cases", name, "units", os.path.basename(path))
                os.makedirs(os.path.dirname(written), exist_ok=True)
                with open(written, "wb") as fh:
                    fh.write(content)
                man.write("%d\t%s\t%s\n" % (idx, written, uname))
                udir = os.path.join(cdir, str(idx))
                for art in ART_NAMES:
                    a = store.artifact(ci, idx, art)
                    if a is None:
                        continue
                    os.makedirs(udir, exist_ok=True)
                    for col, fname in (("ours", art + ".ours"), ("ref", art + ".ref"), ("cut", art + ".ref.cut"),
                                       ("diff", art + ".diff"), ("ours_err", art + ".ours.err"), ("ref_err", art + ".ref.err")):
                        if a.get(col) not in (None, b""):
                            with open(os.path.join(udir, fname), "wb") as fh:
                                fh.write(a[col])
                            n += 1
                    if art == "types":
                        for col, fname in (("walk", "types.walk"), ("diags", "types.diags")):
                            if a.get(col) is not None:
                                with open(os.path.join(udir, fname), "wb") as fh:
                                    fh.write(a[col])
                                n += 1
    return n


def main(argv):
    if len(argv) < 2:
        print("usage: harness.py units | show <key> <art> <ours|ref|cut|diff|walk|diags|message> | export-tree [dir]", file=sys.stderr)
        return 2
    store = Store.open()
    if store is None:
        print("no store at %s — run tests/run.sh first." % store_path(), file=sys.stderr)
        return 2
    cmd = argv[1]
    if cmd == "units":
        for row in store.units():
            print(row[5])
        return 0
    if cmd == "show":
        key, art, col = argv[2], argv[3], argv[4] if len(argv) > 4 else "diff"
        u = store.unit_by_key(key)
        if u is None:
            print("no unit with key %r" % key, file=sys.stderr)
            return 1
        a = store.artifact(u[0], u[1], art)
        if a is None or a.get(col) is None:
            print("no %s for %s/%s" % (col, art, key), file=sys.stderr)
            return 1
        v = a[col]
        sys.stdout.buffer.write(v if isinstance(v, bytes) else (str(v) + "\n").encode())
        return 0
    if cmd == "export-tree":
        root = argv[2] if len(argv) > 2 else "packages/tscaly/tests/out"
        n = _export_tree(store, root)
        print("exported %d artifact files under %s/cases" % (n, root))
        return 0
    print("harness.py: unknown command %r" % cmd, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
