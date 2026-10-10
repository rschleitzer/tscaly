#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# errorsites.py — WHICH REPORTING SITES NEVER FIRE.
#
# ★★★ WHY IT EXISTS (slice 190). `resolveAnonymousTypeMembers` was missing an eight-line
# filter, and the two sites that report the TS2339 the filter makes possible were BOTH
# written — each with a confident note — and neither could fire on any input, because the
# property was always found and the fork was never taken. The code reads complete at both
# ends: `frontier.sh` ranks stops and there is none, `expiredstops.py` tests premises and
# there is no premise, `nocaller.py` finds functions nothing calls and both sites have
# callers, `dupmethods.py` and `rebind.py` key on shapes that are not there. **A written
# report that no input reaches is invisible to every static instrument in this directory,
# and it is exactly the shape a port produces**: the arm gets written, the condition that
# enables it lives in another function, and that other function is still a wall.
#
# ★★★ THE ONLY FORM THAT SEES IT IS DYNAMIC AND ITS PRODUCT IS THE ZERO ROWS. A counter
# per reporting site over the stage-2 corpus, and then the sites with count 0. A count is
# not a defect — a site can legitimately need an input the corpus does not carry — so this
# is a LEAD LIST in `nocaller.py`'s sense and prints enough of each site to be read: the
# enclosing function, the file and line, and the diagnostic code argument as written.
#
# ★★ PER SITE AND NOT PER CODE, WHICH IS THE WHOLE COST OF IT. A histogram over the `C pos
# end code` lines the dump already writes needs no instrumentation at all and would have
# said nothing here: both of slice 190's dead sites report TS2339, a code this port emits
# from live sites hundreds of times. The identity that matters is the CALL SITE, and
# nothing in the emitted artifact carries it.
#
# ★★ SO THE SITE ID IS THREADED IN AS AN ARGUMENT, AND THE PATCH IS MECHANICAL BECAUSE THE
# REWRITE IS A PREFIX. Every reporting call in this port is `this.<name>(`, and every
# definition is `procedure <name>(this,` / `function <name>(this,` — no `this.` — so
# replacing the literal `this.<name>(` with `this.<name>_at(<id>, ` rewrites every call and
# no definition, needs no paren matching, and cannot touch an argument. The `_at` twins are
# generated into the same concept and forward.
#
# ★ THE PROBE WRITES TO STDERR, and `run.sh` has a gate that refuses to run while any
# ported source calls `scaly_eput*` — which is the safety net for a patch left behind, not
# an obstacle: the probe tree is never given to run.sh. `restore` puts both files back from
# the copies `apply` took, and drops `tests/out/.built-from-patched-tree` the way ctl.sh
# does, because a restored source is not a restored binary.
#
# ★★★ THE COLUMN THAT DECIDES A ROW IS THE REFERENCE'S OWN OUTPUT, and it is free: for the
# diagnostic CODE a dead site carries, ask how many corpus units the REFERENCE emits that
# code on, and with what verdict. **A code the reference never emits anywhere is an honest
# zero** — the corpus does not contain the construct, and no amount of reading the guard
# will say more (66 of the first run's 99 rows). A code the reference DOES emit, on units
# that FAIL, is a lead with NAMED WITNESSES: that is how the JSX child elaboration was found
# (three units carrying the reference's TS2745/TS2746 where this port emitted the general
# TS2741). ★It is an attribution and not a proof: many sites pass a `code` VARIABLE, so a
# code maps to several sites and a MATCH only says some site of ours emits it.
#
# ★★ A DEAD SITE IS A LEAD AND MOST LEADS ARE LEGITIMATE, so the report says what it can
# about WHY. Two things carry that: `tests/errorsites-accepted.txt` retires a row whose
# reason has been established, keyed by (concept, function, call text) so a line number may
# move; and each remaining row carries the compiler OPTIONS its enclosing function reads.
# The options are a HINT and are labelled as one — the scan says *this function reads
# `no_implicit_any` somewhere*, not *this site is under it* — because the harness fixes
# every option (checker.scaly's own header lists them) and an option-gated report is the
# commonest honest zero. The second commonest is the harness itself: a unit is ONE FILE, so
# nothing an import can only reach across files is reachable at all.
#
# Usage
#   tools/errorsites.py apply     patch checker.scaly + binder.scaly, write the site table
#   tools/errorsites.py run       run the PATCHED binary over the units in run.db, count
#   tools/errorsites.py report    the zero rows, read off the table and the counts
#   tools/errorsites.py retire    accept every zero whose code the reference emits nowhere
#   tools/errorsites.py restore   put both files back
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
OUT = os.path.join(PKG, "tests", "out")
BAK = os.path.join(OUT, "errorsites.bak")
TABLE = os.path.join(OUT, "errorsites.tsv")
COUNTS = os.path.join(OUT, "errorsites.counts")
ACCEPTED = os.path.join(PKG, "tests", "errorsites-accepted.txt")

# The options the harness fixes (checker.scaly's header and the Checker's own constants).
# Named here so the report can say which of them a dead site's function reads.
OPTIONS = ("no_implicit_any", "strict_null_checks", "exact_optional_property_types",
           "no_implicit_override", "isolated_modules", "erasable_syntax_only",
           "verbatim_module_syntax", "check_js", "module_kind", "script_target",
           "use_define_for_class_fields", "no_unused")

# (file, concept, [(reporter, "<the parameters after `this`>", "returns bool" or "")])
FAMILY = [
    ("checker.scaly", "Checker", [
        ("error_on_node",                            "n: ref[AstNode]?, code: int", ""),
        ("error_on_node_or_null",                    "n: ref[AstNode]?, code: int", ""),
        ("grammar_error_on_node",                    "n: ref[AstNode]?, code: int", "returns bool"),
        ("grammar_error_on_node_or_null",            "n: ref[AstNode]?, code: int", "returns bool"),
        ("grammar_error_on_node_skipped_on_no_emit", "n: ref[AstNode], code: int",  "returns bool"),
        ("grammar_error_on_first_token",             "n: ref[AstNode]?, code: int", "returns bool"),
        ("grammar_error_at_pos",                     "start: int, length: int, code: int", "returns bool"),
    ]),
    ("binder.scaly", "Binder", [
        ("error_on_node", "n: ref[AstNode]?, code: int", ""),
    ]),
]

NOTE = """
    ; ── the error-site probe (tools/errorsites.py) — NOT COMMITTED ─────────────
    ;
    ; Generated. `apply` wrote this block and rewrote every `this.<reporter>(` in
    ; the file to its `_at` twin with a site id; `restore` puts the file back.
    ; The id is printed to stderr on every call, one line per call, and the
    ; product is the sites that never print at all.
    procedure note_error_site(site: int)
    {
        scaly_eputs("ES ")
        scaly_eputi(site as i64)
        scaly_eputnl()
    }
"""

DEF_RE = re.compile(r"^    (?:function|procedure) ([A-Za-z_0-9]+)\(")


def src_path(fname):
    return os.path.join(PKG, "0.1.2", "tscaly", fname)


def enclosing(lines, i):
    """The name of the member whose body line i is in — the nearest `    function`/
    `    procedure` above it. ★ Nearest ABOVE and not a range: the concept is one
    130 000-line body and nothing else in it is indented four spaces."""
    for j in range(i, -1, -1):
        m = DEF_RE.match(lines[j])
        if m:
            return m.group(1)
    return "?"


def is_comment(line):
    return line.lstrip().startswith(";")


def apply():
    os.makedirs(BAK, exist_ok=True)
    table, site = [], 0
    for fname, concept, reporters in FAMILY:
        path = src_path(fname)
        shutil.copy2(path, os.path.join(BAK, fname))
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
        names = sorted((r[0] for r in reporters), key=len, reverse=True)
        for i, line in enumerate(lines):
            if is_comment(line):
                continue
            for name in names:
                needle = "this." + name + "("
                while needle in lines[i]:
                    site += 1
                    lines[i] = lines[i].replace(needle, "this.%s_at(%d, " % (name, site), 1)
                    table.append((site, fname, i + 1, concept, name,
                                  enclosing(lines, i), line.strip()[:160]))
        twins = [NOTE]
        for name, params, ret in reporters:
            kind = "function" if ret else "procedure"
            twins.append(
                "    %s %s_at(this, site: int, %s) %s\n    {\n"
                "        %s.note_error_site(site)\n"
                "        this.%s(%s)\n    }\n"
                % (kind, name, params, ret, concept, name,
                   ", ".join(p.split(":")[0].strip() for p in params.split(","))))
        # ★ The concept's body is the whole file below its `define`, so the twins go in
        # front of the LAST column-0 `}` — the one that closes it.
        close = max(k for k, l in enumerate(lines) if l == "}")
        lines[close:close] = ["".join(twins)]
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines))
    with open(TABLE, "w", encoding="utf-8") as fh:
        fh.write("# site\tfile\tline\tconcept\treporter\tenclosing function\tcall\n")
        for row in table:
            fh.write("%d\t%s\t%d\t%s\t%s\t%s\t%s\n" % row)
    print("patched %d call sites in %d files; site table in %s"
          % (site, len(FAMILY), TABLE))
    open(os.path.join(OUT, ".built-from-patched-tree"), "w").close()
    return 0


def restore():
    n = 0
    for fname, _concept, _r in FAMILY:
        b = os.path.join(BAK, fname)
        if os.path.isfile(b):
            shutil.copy2(b, src_path(fname))
            os.unlink(b)
            n += 1
    open(os.path.join(OUT, ".built-from-patched-tree"), "w").close()
    print("restored %d files from %s — the BINARIES under tests/out are still patched; "
          "run.sh rebuilds them" % (n, BAK))
    return 0


def run():
    sys.path.insert(0, os.path.join(PKG, "tests"))
    import harness as H
    store = H.Store.open(OUT)
    if store is None:
        return err("no store at %s — a run.sh run has to have filled it" % H.store_path(OUT))
    stage = store.meta("stage", "?")
    # ★ TSCALY_ES_FILTER narrows the corpus by case-name substring. It is here for the
    # CONTROL and not for the measurement: a report is only honest over the whole corpus,
    # but proving the instrument can see a known finding needs four units, not 18 450.
    filt = os.environ.get("TSCALY_ES_FILTER", "")
    units = [(r[5], r[6]) for r in store.units(compared_only=True, filt=filt)]
    binary = os.path.join(OUT, "tscaly_types")
    if not os.path.isfile(binary):
        return err("no %s — build the patched tree first" % binary)
    print("probing %d units of the stage-%s corpus%s with %s"
          % (len(units), stage, (" matching %r" % filt) if filt else "", binary))
    scratch = os.path.join(OUT, "chunks")
    os.makedirs(scratch, exist_ok=True)
    jobs = int(os.environ.get("TSCALY_JOBS", os.cpu_count() or 4))
    counts = {}
    import threading
    lock = threading.Lock()

    def one(ci, pending):
        # ★ The blame-and-restart loop of H.run_batch, for its reason: two units of the
        # stage-2 corpus hang this port, and a chunk that dies on one would take the
        # remaining ~1800 units' sites with it — which would show up as DEAD SITES. Every
        # attempt's stderr is counted, including a killed one: a site that printed before
        # the kill did fire.
        attempt = 0
        while pending:
            path = os.path.join(scratch, "probe.%d.%d" % (ci, attempt))
            H.write_units_file(path, pending)
            rc, out, e, timed_out = H.stream_process([binary, "--batch", path], None, 60)
            try:
                os.unlink(path)
            except OSError:
                pass
            complete, in_progress = H.parse_dump_stream(out)
            local = {}
            for line in e.split(b"\n"):
                if line.startswith(b"ES "):
                    s = int(line[3:])
                    local[s] = local.get(s, 0) + 1
            with lock:
                for s, c in local.items():
                    counts[s] = counts.get(s, 0) + c
                counts["#units"] = counts.get("#units", 0) + len(complete)
            done = set(complete)
            if rc == 0 and not timed_out and in_progress is None and len(done) == len(pending):
                return
            if in_progress is not None:
                blamed = in_progress
            elif len(done) < len(pending):
                blamed = pending[len(done)][0]
            else:
                return
            with lock:
                counts["#lost"] = counts.get("#lost", 0) + 1
            pending = [u for u in pending if u[0] not in done and u[0] != blamed]
            attempt += 1

    chunks = H._chunks(units, jobs)
    ts = [threading.Thread(target=one, args=(i, c)) for i, c in enumerate(chunks)]
    for t in ts:
        t.start()
    for t in ts:
        t.join()
    answered = counts.pop("#units", 0)
    lost = counts.pop("#lost", 0)
    with open(COUNTS, "w", encoding="utf-8") as fh:
        fh.write("# stage=%s filter=%r units=%d answered=%d lost=%d\n"
                 % (stage, filt, len(units), answered, lost))
        for s in sorted(counts):
            fh.write("%d\t%d\n" % (s, counts[s]))
    print("%d of %d units answered (%d lost to a crash or a hang); %d of the sites fired; counts in %s"
          % (answered, len(units), lost, len(counts), COUNTS))
    return report()


def load_accepted():
    """→ {(concept, function, call): reason} out of tests/errorsites-accepted.txt."""
    acc = {}
    if not os.path.isfile(ACCEPTED):
        return acc
    with open(ACCEPTED, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) != 4:
                raise SystemExit("errorsites-accepted.txt: not four fields: %r" % line)
            acc[(f[0], f[1], f[2])] = f[3]
    return acc


def options_read_by(fname, line_no):
    """The harness-fixed options named anywhere in the member that holds this line.

    ★ A HINT AND NOT A VERDICT: it answers *this function reads that option somewhere*,
    which is a reason to go and look, never a reason to retire the row.

    ★★ THE WHOLE MEMBER, UP AND DOWN. A first version walked upward only and reported
    NOTHING for `check_member_for_override_modifier`'s six rows — every one of which sits
    ABOVE the `if no_implicit_override = false` that gates them. A scan that can only see
    backwards answers about the wrong half of a function.
    """
    lines = open(src_path(fname), encoding="utf-8").read().split("\n")
    i = min(line_no - 1, len(lines) - 1)
    start = 0
    for j in range(i, -1, -1):
        if DEF_RE.match(lines[j]):
            start = j
            break
    end = len(lines)
    for j in range(i + 1, len(lines)):
        if DEF_RE.match(lines[j]):
            end = j
            break
    names = set()
    for line in lines[start:end]:
        if is_comment(line):
            continue
        for o in OPTIONS:
            if o in line:
                names.add(o)
    return sorted(names)


def code_witnesses():
    """→ ({code name: number}, {code: {verdict: units}}, stage) off the run store.

    The reference's own `C pos end code` lines over whatever corpus the store holds.

    ★★★ WHATEVER CORPUS THE STORE HOLDS — which is why every caller has to ask what that
    is. A FILTERED run leaves five units in `run.db`, and *the reference emits this code
    nowhere* is then true of almost every code in the file. `retire` refuses anything but a
    full stage-2 store for exactly that reason; `report` prints the stage it read.
    """
    import re as _re
    num = {}
    dc = os.path.join(PKG, "0.1.2", "tscaly", "DiagnosticCodes.scaly")
    for line in open(dc, encoding="utf-8"):
        m = _re.match(r"define (Diag\w+):\s+int (\d+)", line.strip())
        if m:
            num[m.group(1)] = int(m.group(2))
    sys.path.insert(0, os.path.join(PKG, "tests"))
    import harness as H
    store = H.Store.open(OUT)
    if store is None:
        return num, {}, "?"
    stage = store.meta("stage", "?")
    per = {}
    for ci, idx, ref, v in store.db.execute("SELECT ci, idx, ref, verdict FROM artifacts WHERE art='types'"):
        if not ref:
            continue
        for line in ref.split(b"\n"):
            if line.startswith(b"C "):
                f = line.split(b" ")
                if len(f) >= 4 and f[3].isdigit():
                    per.setdefault(int(f[3]), {}).setdefault(v, set()).add((ci, idx))
    return num, per, stage


def code_of(call, num):
    import re as _re
    for m in _re.finditer(r"Diag\w+", call):
        if m.group(0) in num:
            return num[m.group(0)]
    return None


def report():
    if not os.path.isfile(TABLE):
        return err("no site table at %s — `apply` writes it" % TABLE)
    if not os.path.isfile(COUNTS):
        return err("no counts at %s — `run` writes it" % COUNTS)
    rows, counts, head = [], {}, ""
    with open(TABLE, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            f = line.rstrip("\n").split("\t")
            rows.append((int(f[0]), f[1], int(f[2]), f[3], f[4], f[5], f[6]))
    with open(COUNTS, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#"):
                head = line.strip()
                continue
            s, c = line.split("\t")
            counts[int(s)] = int(c)
    acc = load_accepted()
    num, per_code, wstage = code_witnesses()
    dead = [r for r in rows if counts.get(r[0], 0) == 0]
    retired = [r for r in dead if (r[3], r[5], r[6]) in acc]
    open_rows = [r for r in dead if (r[3], r[5], r[6]) not in acc]
    print(head)
    print("%d reporting sites, %d fired, %d never fired — %d of those carry a reason in %s"
          % (len(rows), len(rows) - len(dead), len(dead), len(retired),
             os.path.relpath(ACCEPTED, PKG)))
    print("%d rows are OPEN:\n" % len(open_rows))
    by_fn = {}
    for r in open_rows:
        by_fn.setdefault((r[3], r[5]), []).append(r)
    for (concept, fn), rs in sorted(by_fn.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        opts = options_read_by(rs[0][1], rs[0][2])
        hint = ("   [reads %s]" % ", ".join(opts)) if opts else ""
        print("%s.%s — %d dead site%s%s"
              % (concept, fn, len(rs), "" if len(rs) == 1 else "s", hint))
        for r in rs:
            code = code_of(r[6], num)
            w = per_code.get(code, {})
            n = sum(len(u) for u in w.values())
            if not per_code:
                col = ""
            elif n == 0:
                col = "   [the reference emits %s nowhere in the stage-%s corpus]" % (
                    ("TS%d" % code) if code else "this code", wstage)
            else:
                bad = {k: len(u) for k, u in w.items() if k != "MATCH"}
                col = "   [ref TS%d on %d units%s]" % (
                    code, n, (", " + ", ".join("%d %s" % (v, k) for k, v in sorted(bad.items()))) if bad else "")
            print("    %s:%d  %s%s" % (r[1], r[2], r[6], col))
    return 0


def retire():
    """Append an accepted row for every dead site whose code the REFERENCE emits nowhere.

    ★★★ THE REASON IS A MEASUREMENT AND IT IS WRITTEN AS ONE, with the corpus it was taken
    over: *the reference emits TS<n> on no unit of the stage-2 corpus (18 455 units)*. It
    says the corpus cannot reach the site, NOT that the site is right — which is the only
    honest thing a zero can say, and exactly why these rows are retired rather than deleted:
    a corpus that grows can bring one back, and the row then has to be re-established.
    """
    if not os.path.isfile(TABLE) or not os.path.isfile(COUNTS):
        return err("run `apply` and `run` first")
    counts = {}
    units = "?"
    with open(COUNTS, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#"):
                import re as _re
                m = _re.search(r"units=(\d+)", line)
                if m:
                    units = m.group(1)
                continue
            a, b = line.split("\t")
            counts[int(a)] = int(b)
    num, per_code, stage = code_witnesses()
    sys.path.insert(0, os.path.join(PKG, "tests"))
    import harness as H
    store = H.Store.open(OUT)
    if store is None or store.meta("stage") != "2" or store.meta("filter"):
        return err("retire needs a FULL stage-2 store in run.db (this one is stage %s, filter %r) — "
                   "over a filtered run every code looks unemitted"
                   % (store.meta("stage", "?") if store else "?", store.meta("filter", "") if store else "?"))
    acc = load_accepted()
    add = []
    with open(TABLE, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            f = line.rstrip("\n").split("\t")
            if counts.get(int(f[0]), 0):
                continue
            key = (f[3], f[5], f[6])
            if key in acc:
                continue
            code = code_of(f[6], num)
            if code is None or per_code.get(code):
                continue
            acc[key] = 1
            add.append((f[3], f[5], f[6],
                        "CORPUS the reference emits TS%d on no unit of the stage-%s corpus (%s units), "
                        "so nothing here can reach this site. It says the corpus cannot test the site, "
                        "not that the site is right." % (code, stage, units)))
    with open(ACCEPTED, "a", encoding="utf-8") as fh:
        for row in add:
            fh.write("%s\t%s\t%s\t%s\n" % row)
    print("retired %d rows into %s" % (len(add), os.path.relpath(ACCEPTED, PKG)))
    return 0


def err(msg):
    print("errorsites.py: " + msg, file=sys.stderr)
    return 2


def main(argv):
    cmds = {"apply": apply, "restore": restore, "run": run, "report": report, "retire": retire}
    if len(argv) < 2 or argv[1] not in cmds:
        return err("usage: errorsites.py apply | run | report | retire | restore")
    return cmds[argv[1]]()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
