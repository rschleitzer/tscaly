#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# compare.py — the case loop of run.sh, as ONE process.
#
# ★★★ THIS FILE CHANGES THE COST OF THE MEASUREMENT AND NOT THE MEASUREMENT.
# Every rule the bash loop encoded is reproduced here deliberately, and the two
# were diffed over the whole corpus before the loop was retired:
#
#   * the ORACLE'S LAST COLUMN IS DROPPED BY FIELD COUNT, not by a regex and not
#     by a normalisation. `cut_fields` is `cut -d' ' -f1-<keep>` and nothing else:
#     single-space delimiters, empty fields preserved, a line with fewer fields
#     passed through whole, the trailing newline kept or absent as the input had
#     it. Verified byte-for-byte against BSD `cut` over all 2502 artifacts of a
#     green run before this file was committed. The root CLAUDE.md's `od -c`
#     lesson is why that check exists at all: a normalisation in the comparison
#     hides exactly the class it hides in the comparison.
#
#   * NO PIPELINE AROUND A BINARY WHOSE EXIT CODE IS READ. `subprocess.run`
#     answers the process's own status; that is the point.
#
#   * `diff` IS STILL A SUBPROCESS, on the failure path only. The `.diff` file is
#     a diagnosis artifact and its first line is quoted into the failure message,
#     so reproducing diff's normal format in Python would be a normalisation of
#     the evidence for no gain — it runs on failing artifacts, which a green run
#     has none of.
#
#   * THE REPORT IS ORDER-STABLE. The work runs on a thread pool, so completion
#     order is arbitrary; results are keyed by (case index, unit index, artifact)
#     and accumulated in that order afterwards. A parallel run and a serial one
#     print the same bytes.
#
# ★ ONE DELIBERATE TIGHTENING, stated because it is a change: `is_accepted` was
# `grep -q "^<case>\t<artifact>\t"`, i.e. the case key was read as a BRE, so a
# key containing `.` — every multi-file unit key does — matched any character in
# that position. Here it is an exact prefix match on the first two tab-separated
# fields. Strictly narrower, and provably neutral on today's tree: accepted.txt
# carries zero entries, so both readings answer false everywhere.
#
# ★ Parallelism is spawn-bound rather than CPU-bound (the whole bash loop ran at
# 5-20 % CPU), and the pool size was MEASURED rather than reasoned: on a
# 10-core box, spawning 600 dumps runs at 210 proc/s serially, 837 at 4 threads,
# **952 at 8**, and then back DOWN — 878 at 16, 800 at 24. So the default is the
# core count, not a multiple of it, and going wider is slower rather than
# neutral. TSCALY_JOBS overrides it.

import os
import re
import shutil
import hashlib
import time
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor


def cut_fields(data: bytes, keep: int) -> bytes:
    """Exactly `cut -d' ' -f1-keep`, on bytes."""
    if not data:
        return b""
    trailing_nl = data.endswith(b"\n")
    lines = data.split(b"\n")
    if trailing_nl:
        lines = lines[:-1]
    out = b"\n".join(b" ".join(line.split(b" ")[:keep]) for line in lines)
    return out + (b"\n" if trailing_nl else b"")


TIMED_OUT = "TIMEOUT"


def run_capture(argv, out_path, err_path, timeout=None):
    """Run argv, write stdout/stderr to the two paths, answer (rc, stdout bytes).

    A stage-1 dump is tens of kilobytes (29 547 bytes is that corpus's maximum),
    so holding stdout in memory costs nothing and saves reading it back; the
    submodule corpus has larger cases, and the pool bounds how many are in flight.

    ★ THE TIMEOUT IS A STAGE-2 REQUIREMENT AND IT IS NOT A NORMALISATION. A
    non-terminating parse — the shape §3.5bf records, a scan that never advances —
    is a defect, and without a bound one of them replaces the entire measurement
    with nothing. It answers TIMED_OUT rather than a status, so the verdict layer
    can name it instead of folding it into "exited N". Neutral on stage 1: nothing
    there comes near the bound, which the byte-identical report proves.
    """
    try:
        proc = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        with open(out_path, "wb") as fh:
            fh.write(exc.stdout or b"")
        with open(err_path, "wb") as fh:
            fh.write(exc.stderr or b"")
        return TIMED_OUT, b""
    with open(out_path, "wb") as fh:
        fh.write(proc.stdout)
    with open(err_path, "wb") as fh:
        fh.write(proc.stderr)
    return proc.returncode, proc.stdout


# ── the REFERENCE cache ──────────────────────────────────────────────────────
#
# ★★★ HALF THE DUMP WORK IS THE ORACLE, AND THE ORACLE IS A PURE FUNCTION.
# Measured over 300 units, ten-wide: both sides 11.22 ms/unit, our side 5.52,
# the oracle 5.28 — so the reference costs 94 s of a stage-2 run and it computes
# the SAME ANSWER every time. Checked rather than assumed: all five oracles are
# byte-identical across two runs on the same unit.
#
# ★★★ THE KEY IS THE STAMP THAT ALREADY EXISTS, which is what makes this safe
# rather than clever. run.sh's `oracle_stamp` is the hashes of the six oracle
# sources, the submodule HEAD sha and the Go version — i.e. the complete statement
# of *which reference is this* — and the run REFUSES to start at all if the
# submodule is dirty, so no edited lib file can ever reach a key. The unit's own
# BYTES are the other half; a path is not enough, because a case can be rewritten
# without moving.
#
# ★★ WHAT A STALE ENTRY WOULD COST is the reason the key is over-specified rather
# than minimal: a wrong `.ref` is not a crash, it is a comparison against the
# wrong reference — the whole suite going green or red for a reason no diff
# explains. Every input the oracle reads is either in the stamp or in the unit.
# `TSCALY_NO_REFCACHE=1` turns it off, and the hit/miss counts are printed,
# because a cache whose hit rate is invisible is a cache nobody can debug.
#
# ★ It lives OUTSIDE `packages/` by default. The root CLAUDE.md records that a
# 443 317-file artifact tree under `packages/` reddens the LSP suite by making
# scalyls' `*.scaly` walk time out; a cache is derived data with no reason to sit
# in that walk's path.

_REF_MAGIC = b"TSCALYREF2\n"


class UnitRefCache:
    """The five reference answers of ONE unit, in one file.

    ★★★ ONE ENTRY PER UNIT AND NOT PER (UNIT, ARTIFACT), because the cost that
    hurt was file CREATION and not bytes. The first version wrote 89 460 entries
    for a stage-2 run and the profile put 37 % of the compare phase in `ref` —
    serving a cache — while the cold run paid +22 % CPU to write it. Five answers
    in one file is a 5x cut in opens on both paths, and it is the same arithmetic
    that makes `/usr/bin/true` a 1.58 ms program: on this platform a small file
    costs about 4 ms to create no matter what is in it.

    ★★ AN ENTRY IS ALL-OR-NOTHING. A unit whose five answers are not all present
    is not stored, so a partial file can never be read back as a complete one —
    and a TIMEOUT is never stored at all, because it is a statement about this
    machine at this moment rather than about the reference.
    """

    def __init__(self, path):
        self.path = path
        self.have = {}
        self.fresh = {}
        self.spoiled = False

    def load(self):
        if self.path is None:
            return
        try:
            with open(self.path, "rb") as fh:
                blob = fh.read()
        except OSError:
            return
        if not blob.startswith(_REF_MAGIC):
            return
        body = blob[len(_REF_MAGIC):]
        try:
            while body:
                head, body = body.split(b"\n", 1)
                art, rc_s, n_s, e_s = head.split(b" ")
                rc, n, e = int(rc_s), int(n_s), int(e_s)
                if n + e > len(body):
                    self.have = {}
                    return
                self.have[art.decode()] = (rc, body[:n], body[n:n + e])
                body = body[n + e:]
        except ValueError:
            self.have = {}

    def get(self, art):
        return self.have.get(art)

    def put(self, art, rc, out, err):
        self.fresh[art] = (rc, out, err)

    def store(self, arts):
        if self.path is None or self.spoiled or not self.fresh:
            return
        merged = dict(self.have)
        merged.update(self.fresh)
        if any(a not in merged for a in arts):
            return
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            tmp = "%s.%d.tmp" % (self.path, threading.get_ident())
            with open(tmp, "wb") as fh:
                fh.write(_REF_MAGIC)
                for a in arts:
                    rc, out, err = merged[a]
                    fh.write(b"%s %d %d %d\n" % (a.encode(), rc, len(out), len(err)))
                    fh.write(out)
                    fh.write(err)
            os.replace(tmp, self.path)
        except OSError:
            pass


def ref_cache_path(ctx, case_file):
    """The key: the oracle STAMP, the exact path, and the exact bytes.

    ★★★ THE PATH IS PART OF IT AND LEAVING IT OUT WAS THE FIRST THING THIS CACHE
    GOT WRONG — §3.5ai, *a file's NAME is an input to the parse*, walked into by
    the person who had been editing that section's neighbours the same afternoon.
    The oracle picks the ScriptKind and the `.d.ts` ambient flag out of the FILE
    NAME, so two units with identical bytes and different names have different
    answers. Keyed on bytes alone the very first run reported **189 hits into an
    empty cache** — the corpus is full of tiny identical fixtures — and went RED on
    four yardsticks at once.

    ★★ The ARTIFACT is no longer in the key because it is inside the ENTRY; the
    five oracle binaries are covered by the stamp like everything else about the
    reference.
    """
    if ctx.refcache is None:
        return None
    try:
        with open(case_file, "rb") as fh:
            unit = fh.read()
    except OSError:
        return None
    h = hashlib.sha256()
    h.update(ctx.refkey)
    h.update(b"\0")
    h.update(case_file.encode("utf-8", "surrogateescape"))
    h.update(b"\0")
    h.update(unit)
    k = h.hexdigest()
    return os.path.join(ctx.refcache, k[:2], k)


# ── the classifications, moved off `tr` and `case` ───────────────────────────
#
# Both were a subshell plus a `tr` per unit in the bash loop. The suffix sets and
# the order of the tests are the loop's, unchanged; see run.sh for the argument
# behind each one.

_COMPARED_SUFFIXES = (
    ".ts", ".mts", ".cts",     # TypeScript, declaration units included
    ".tsx",                    # the JSX grammar, slice 20
    ".jsx",                    # ScriptKindJSX, slice 22
    ".js", ".cjs", ".mjs",     # ScriptKindJS, slice 22
    ".json",                   # the second grammar, slice 19
)


def classify_unit(unit_name: str):
    """None when the unit is compared, else the skip reason."""
    low = unit_name.lower()
    return None if low.endswith(_COMPARED_SUFFIXES) else "other"


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


class Ctx:
    pass


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


# ── one artifact of one unit ─────────────────────────────────────────────────
#
# A faithful transcription of compare_one, including the ORDER of its checks:
# both binaries run before either exit code is read, so `jsdoc.ref` exists even
# when our dumper failed — which is what the jsdoc-bearing count depends on.


# ── TSCALY_PROFILE: where a run's wall time actually goes ────────────────────
#
# ★★★ IT EXISTS BECAUSE THREE MICRO-BENCHMARKS IN A ROW WERE WRONG, each in the
# flattering direction. Sampling 200 of 18 876 cases said our five dumps cost 78 s
# over the corpus; the profile says 2 037 s across threads. A sample that size
# misses the SIZE TAIL by construction — ten cases are 48 % of the corpus's bytes
# — and, worse, the benchmark ran the dumper with `capture_output` while the real
# run has it WRITE TWO FILES per artifact. Both errors point the same way, and
# nobody re-checks a number that says the thing is cheap.
#
# ★ The two phase timers are wall; the in-task slots are summed ACROSS THREADS, so
# their total over the phase's wall time is the effective parallelism — 7.5x on
# stage 2, which is what says the pool is not the thing to fix. Opt-in, on stderr,
# and the report it accompanies is byte-identical to an unprofiled run's.

def _tick(ctx, slot, t0):
    if ctx.profile is None:
        return
    dt = time.time() - t0
    with ctx.prof_lock:
        ctx.profile[slot] = ctx.profile.get(slot, 0.0) + dt


# ★★★ THE `types` ARTIFACT IS DUMPED IN `--sections` MODE, WHICH IS WHERE
# diagcheck's AND walkcheck's 35 784 PROCESSES WENT. Both instruments used to
# spawn this same program once per unit — 216 s on stage 2 — to recompute a parse
# and a bind that had just been performed in the same minute. One invocation now
# prints all three answers and this writes the two extra ones beside the dump;
# the instruments read files.
#
# ★★ The DUMP section is what lands in `types.ours`, and it is byte-identical to
# what plain mode prints — proven over the whole corpus before the switch, along
# with the other two sections, against the three separate invocations. See
# tscaly_types.scaly for why each section gets a FRESH Checker in its own mode's
# order, and for the one-stream rule the first attempt broke.
_SEP_DIAGS = b"==== TSCALY-SECTION diags\n"
_SEP_DUMP = b"==== TSCALY-SECTION dump\n"


def compare_one(ctx, name, art, keep, ours_bin, ref_bin, case_file, work, uc):
    _t = time.time()
    if art == "types" and ctx.sections:
        rc, blob = run_capture([ours_bin, "--sections", case_file],
                               f"{work}/{art}.sections", f"{work}/{art}.ours.err",
                               ctx.timeout)
        if rc is TIMED_OUT or _SEP_DIAGS not in blob or _SEP_DUMP not in blob:
            # A malformed sections blob is a harness failure and never a verdict:
            # fall back to the three-mode behaviour rather than compare a fragment.
            ours_rc, ours_out = run_capture(
                [ours_bin, case_file], f"{work}/{art}.ours", f"{work}/{art}.ours.err",
                ctx.timeout)
            for suffix in (".diags", ".walk"):
                try:
                    os.unlink(f"{work}/{art}{suffix}")
                except OSError:
                    pass
        else:
            walk, rest = blob.split(_SEP_DIAGS, 1)
            diags, dump = rest.split(_SEP_DUMP, 1)
            with open(f"{work}/{art}.walk", "wb") as fh:
                fh.write(walk)
            with open(f"{work}/{art}.diags", "wb") as fh:
                fh.write(diags)
            with open(f"{work}/{art}.ours", "wb") as fh:
                fh.write(dump)
            ours_rc, ours_out = rc, dump
        try:
            os.unlink(f"{work}/{art}.sections")
        except OSError:
            pass
    else:
        ours_rc, ours_out = run_capture(
            [ours_bin, case_file], f"{work}/{art}.ours", f"{work}/{art}.ours.err",
            ctx.timeout)
    _tick(ctx, "ours", _t)

    # ★ The ORDER above is load-bearing and the cache does not change it: both
    # sides are produced before either exit code is read, so `jsdoc.ref` exists
    # even when our dumper failed. A cache HIT still writes both files.
    _t = time.time()
    hit = uc.get(art)
    if hit is not None:
        ref_rc, ref_out, ref_err = hit
        with open(f"{work}/{art}.ref", "wb") as fh:
            fh.write(ref_out)
        with open(f"{work}/{art}.ref.err", "wb") as fh:
            fh.write(ref_err)
        with ctx.ref_lock:
            ctx.ref_hits += 1
    else:
        ref_rc, ref_out = run_capture(
            [ref_bin, case_file], f"{work}/{art}.ref", f"{work}/{art}.ref.err",
            ctx.timeout)
        with ctx.ref_lock:
            ctx.ref_misses += 1
        # ★ A TIMEOUT IS NOT AN ANSWER AND IS NEVER CACHED — it is a statement
        # about this machine at this moment, and storing one would make a
        # transient hang permanent for every later run. It also SPOILS the unit's
        # entry, so the other four answers are not written behind a hole.
        if ref_rc is TIMED_OUT:
            uc.spoiled = True
        else:
            with open(f"{work}/{art}.ref.err", "rb") as fh:
                uc.put(art, ref_rc, ref_out, fh.read())
    _tick(ctx, "ref", _t)
    _t = time.time()

    if ours_rc is TIMED_OUT:
        return "TIMEOUT", f"{art}/{name}: our dumper timed out after {ctx.timeout}s"
    if ref_rc is TIMED_OUT:
        return "TIMEOUT", (f"{art}/{name}: the ORACLE timed out after {ctx.timeout}s"
                           " — suspect the harness, not the port")

    if ours_rc != 0:
        return "FAIL", f"{art}/{name}: our dumper exited {ours_rc}"
    # ★★★ EXIT 3 FROM THE ORACLE IS "THE REFERENCE COULD NOT ANSWER THIS UNIT",
    # and it is a class rather than a failure — but only when it is ARGUED. Only
    # tests/oracle/types.go uses it: the checker nil-dereferences on some valid
    # inputs (its header names the shape and bounds it), so there is nothing to
    # compare against, which is a MISSING MEASUREMENT and not a deviation of ours.
    #
    # ★★★ AND IT GOES THROUGH accepted.txt, for slice 26's c4 reason: a column
    # that cannot fail the run is a column that is not measured. An oracle exiting
    # 3 on EVERY unit would otherwise read as "no reference answer" 17 807 times
    # and the run would still say OK. So a known hole is an UPSTREAM entry with
    # its evidence, and an unknown one is a failure like any other.
    if ref_rc == 3:
        if (name, art) in ctx.accepted:
            return "REFCRASH", f"{art}/{name}"
        return "FAIL", (f"{art}/{name}: the ORACLE panicked inside the reference"
                        " (exit 3) and no accepted.txt entry argues it")
    if ref_rc != 0:
        return "FAIL", (f"{art}/{name}: the ORACLE exited {ref_rc}"
                        " — suspect the harness, not the port")

    # ★★★ `no-tree` is NOT an honest unported report — it is the parser answering
    # NULL with no unported record, a port defect wearing the unported column's
    # clothes. A hard failure here, as in the bash loop.
    if _has_line_prefix(ours_out, b"UNPORTED 0 no-tree "):
        return "FAIL", (f"{art}/{name}: no-tree — the parser answered null with NO"
                        " unported record, which is a port defect and not an"
                        " unported construct")

    if _has_line_prefix(ours_out, b"UNPORTED "):
        return "UNPORTED", None

    _tick(ctx, "verdict", _t)
    _t = time.time()
    cut = cut_fields(ref_out, keep) if keep > 0 else ref_out
    with open(f"{work}/{art}.ref.cut", "wb") as fh:
        fh.write(cut)

    is_acc = (name, art) in ctx.accepted

    _tick(ctx, "cut", _t)
    if cut == ours_out:
        # A deviation that no longer deviates. Left unreported, accepted.txt rots
        # into a list of things that used to be true.
        return ("STALE" if is_acc else "MATCH"), None

    if is_acc:
        return "ACCEPTED", None

    with open(f"{work}/{art}.diff", "wb") as fh:
        subprocess.run(["diff", f"{work}/{art}.ref", f"{work}/{art}.ours"],
                       stdout=fh, stderr=subprocess.STDOUT)
    first = _first_line(f"{work}/{art}.diff")
    return "FAIL", f"{art}/{name}: {first}"


def _has_line_prefix(data: bytes, prefix: bytes) -> bool:
    if data.startswith(prefix):
        return True
    return (b"\n" + prefix) in data


def _first_line(path):
    try:
        with open(path, "r", errors="surrogateescape") as fh:
            return fh.readline().rstrip("\n")
    except OSError:
        return ""


# ★ THE SECOND FIELD IS THE `cut -d' ' -f1-<keep>` WIDTH, and 0 means NO CUT.
# The first three oracles carry a trailing kind NAME for readability, which our
# side does not emit — dropping it by field count is what makes the comparison
# possible without a 386-entry name table here. The symbols dump carries no such
# column, deliberately: its lines have different field counts (a symbol line has
# nine, a declaration line five), so ONE keep width cannot mean "everything but
# the name" for all of them, and a per-line rule would be a normalisation inside
# the comparison. Numeric kinds are looked up in tscaly/Kind.scaly when a diff
# has to be read.
ARTIFACTS = (("tokens", 4), ("ast", 5), ("jsdoc", 5), ("symbols", 0), ("types", 0))


def main():
    ctx = Ctx()
    out = os.environ["TSCALY_OUT"]
    ctx.accepted = load_accepted(os.environ["TSCALY_ACCEPTED"])
    sub_prefix = os.environ["TSCALY_SUB_PREFIX"]
    pkg_prefix = os.environ["TSCALY_PKG_PREFIX"]
    ts_prefix = os.environ.get("TSCALY_TS_PREFIX", "")
    filt = os.environ.get("TSCALY_FILTER", "")
    jobs = int(os.environ.get("TSCALY_JOBS") or min(16, os.cpu_count() or 8))
    stage = int(os.environ.get("TSCALY_STAGE") or 1)
    ctx.timeout = float(os.environ.get("TSCALY_TIMEOUT") or 60)

    # ── the reference cache ──────────────────────────────────────────────────
    #
    # ★ The key material is run.sh's own oracle STAMP, handed down rather than
    # recomputed here: one definition of *which reference is this*, in the place
    # that already refuses to run against a dirty submodule.
    # ★ The escape hatch exists so the switch can be A/B-ed against itself, which
    # is the only thing that licenses it (see compare_one).
    ctx.sections = not os.environ.get("TSCALY_NO_SECTIONS")
    ctx.prof_lock = threading.Lock()
    ctx.profile = {} if os.environ.get("TSCALY_PROFILE") else None
    ctx.wall = {}
    ctx.ref_lock = threading.Lock()
    ctx.ref_hits = 0
    ctx.ref_misses = 0
    ctx.refcache = None
    ctx.refkey = b""
    stamp = os.environ.get("TSCALY_ORACLE_STAMP", "")
    cachedir = os.environ.get("TSCALY_REFCACHE", "")
    if stamp and cachedir and not os.environ.get("TSCALY_NO_REFCACHE"):
        ctx.refkey = hashlib.sha256(stamp.encode()).digest()
        ctx.refcache = cachedir
        os.makedirs(cachedir, exist_ok=True)

    bins = {art: (f"{out}/tscaly_{art}", f"{out}/oracle_{art}") for art, _ in ARTIFACTS}
    split_bin = f"{out}/oracle_split"

    cases = [line.rstrip("\n") for line in sys.stdin if line.strip()]

    # Clear the whole per-case tree, not just the cases about to run: a stale
    # result directory is indistinguishable from a fresh one when something later
    # reads it.
    shutil.rmtree(f"{out}/cases", ignore_errors=True)

    # ★ THE THREE PREFIXES ARE THREE KEY SPACES, and the submodule corpus needs
    # its own. 15 relative paths exist in BOTH corpora (compiler/checkInheritedProperty.ts
    # among them), so one shared space would silently let one case's directory,
    # artifacts and verdict stand in for another's. The `submodule_` prefix mirrors
    # the reference's own separation, testdata/baselines/reference/submodule/.
    # Order matters: the TS prefix sits UNDER the typescript-go checkout, so it
    # must be tested first or sub_prefix would never see it — as it happens the two
    # do not nest, but relying on that is exactly the kind of luck this file avoids.
    selected = []
    for case_file in cases:
        name = case_file
        if ts_prefix and name.startswith(ts_prefix):
            name = "submodule/" + name[len(ts_prefix):]
        elif name.startswith(sub_prefix):
            name = name[len(sub_prefix):]
        elif name.startswith(pkg_prefix):
            name = name[len(pkg_prefix):]
        if name.endswith(".ts"):
            name = name[:-3]
        name = name.replace("/", "_")
        if filt and filt not in name:
            continue
        selected.append((case_file, name))

    # ★★★ A DUPLICATE KEY IS A SILENT HALVING, so it is refused rather than
    # measured. The key is the path with `/` folded to `_`, which is not injective:
    # `a/b_c.ts` and `a_b/c.ts` collide. Today's two corpora contain no collision —
    # counted, 0 of 12 760 — but "the corpus happens not to contain it" is the same
    # standing this file spends its comments arguing against, and the cost of the
    # check is a dict.
    seen_keys = {}
    for case_file, name in selected:
        if name in seen_keys:
            print(f"compare.py: two cases map to one key {name!r}:\n"
                  f"    {seen_keys[name]}\n    {case_file}\n"
                  "  One would overwrite the other's artifacts and verdict. Give the"
                  " key space another separator before running this corpus.",
                  file=sys.stderr)
            return 2
        seen_keys[name] = case_file

    # ── progress, on stderr, and only where a run is long enough to need it ───
    #
    # ★ STAGE 1 MUST STAY SILENT HERE. ctl.sh captures a run as `2>&1` and compares
    # the whole report byte for byte across a 45-control battery, so a progress line
    # on stage 1 would not be noise — it would be a diff in every control's
    # baseline. Gated on the stage, and stderr even then, so the report itself never
    # carries it.
    progress_lock = threading.Lock()
    progress = {"done": 0}

    def tick(total, every, what):
        with progress_lock:
            progress["done"] += 1
            n = progress["done"]
        if stage >= 2 and (n % every == 0 or n == total):
            print(f"  {what} {n}/{total}", file=sys.stderr, flush=True)

    # ── phase A: the reference's own splitter, one process per case ──────────
    def do_split(item):
        case_file, name = item
        case_work = f"{out}/cases/{name}"
        os.makedirs(case_work, exist_ok=True)
        rc, _ = run_capture([split_bin, case_file, f"{case_work}/units"],
                            f"{case_work}/units.manifest", f"{case_work}/units.err",
                            ctx.timeout)
        tick(len(selected), 1000, "split")
        return rc

    _phase_t0 = time.time()
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        split_rcs = list(pool.map(do_split, selected))
    ctx.wall["split"] = time.time() - _phase_t0
    progress["done"] = 0

    # ── phase B: the unit list, in the loop's own order ──────────────────────
    counters = {}
    for art, _ in ARTIFACTS:
        for k in ("matched", "unported", "failed", "accepted", "stale", "timeout",
                  "refcrash"):
            counters[f"{k}_{art}"] = 0
    counters["cases_seen"] = 0
    counters["skip_jsx"] = 0
    counters["skip_other"] = 0
    counters["json_compared"] = 0
    counters["js_compared"] = 0
    counters["tsx_compared"] = 0
    counters["jsx_compared"] = 0
    counters["jsdoc_bearing"] = 0
    # ★ Slice 24: how many units carry a JS-SYNTAX diagnostic, and how many there
    # are. The J section is empty for every file that is not JavaScript, so its
    # matched count would otherwise read as coverage it does not have — the same
    # argument jsdoc_bearing rests on, one section over.
    counters["js_diag_units"] = 0
    counters["js_diag_lines"] = 0
    # ★★★ Slice 26: how many units CARRY a symbol, and how many bind diagnostics
    # the corpus holds. Both counted off the REFERENCE dump, and the first one is
    # not decoration: control c1 answered a dump of `f 0 0` — no symbols, no tables,
    # symbolCount 0 — for every unit, and **44 of 865 MATCHED**, because that is
    # exactly what the reference produces for a unit with no declarations in it. So
    # a matched total on this yardstick includes units where both sides agree by
    # producing nothing, the same way the jsdoc one does, and the number has to be
    # printed or it reads as coverage it does not have.
    counters["symbol_bearing"] = 0
    counters["bind_diag_units"] = 0
    counters["bind_diag_lines"] = 0
    failures = []
    stales = []
    refcrashes = []

    tasks = []          # (order key, unit record, artifact, keep)
    split_failures = []
    for ci, ((case_file, name), rc) in enumerate(zip(selected, split_rcs)):
        counters["cases_seen"] += 1
        case_work = f"{out}/cases/{name}"
        if rc != 0:
            detail = (f"the splitter timed out after {ctx.timeout}s"
                      if rc is TIMED_OUT else _first_line(case_work + "/units.err"))
            split_failures.append((ci, f"split/{name}: {detail}"))
            counters["failed_tokens"] += 1
            counters["failed_ast"] += 1
            continue

        with open(f"{case_work}/units.manifest", "r", errors="surrogateescape") as fh:
            manifest = [ln.rstrip("\n") for ln in fh]
        units = [ln for ln in manifest if ln != ""]   # `grep -c .`
        unit_count = len(units)

        for ui, line in enumerate(manifest):
            # ★★★ THE MANIFEST IS TAB-SEPARATED SINCE STAGE 2, and it had to become
            # so. This was `line.split(None, 2)`, the transcription of the loop's
            # `read -r idx written unit_name` — and a unit NAME may contain a space
            # (compiler/sourceMapPercentEncoded.ts has one), which truncated the
            # written PATH at that space and sent our dumper after a file that does
            # not exist. Reported as `cannot read <prefix>` on all three yardsticks,
            # i.e. as a port defect. See tests/oracle/split.go.
            if line == "":
                continue
            parts = line.split("\t")
            if len(parts) != 3 or not parts[1]:
                print(f"compare.py: {name}: unreadable manifest line {line!r} — the"
                      " splitter and this reader disagree about the format, which is a"
                      " harness bug and not a result.", file=sys.stderr)
                return 2
            idx, written, unit_name = parts

            if classify_unit(unit_name) is not None:
                counters["skip_other"] += 1
                continue

            # A single-unit case keeps its own key, so every accepted.txt entry and
            # every number in CLAUDE.md's tables still refers to the same thing.
            if unit_count == 1:
                key = name
            else:
                key = name + "@" + unit_name.lstrip("/").replace("/", "_")

            bucket = kind_bucket(unit_name)
            if bucket:
                counters[bucket + "_compared"] += 1

            work = f"{case_work}/{idx}"
            os.makedirs(work, exist_ok=True)
            for art, keep in ARTIFACTS:
                tasks.append(((ci, ui, art), key, art, keep, written, work))

    # ── phase C: every UNIT on the pool, its five artifacts inside ───────────
    #
    # ★★★ THE POOL'S ITEM IS A UNIT AND NOT AN ARTIFACT, so that the reference
    # cache is ONE file per unit — see UnitRefCache for why file count is the cost
    # that matters. The five artifacts of a unit then run in ARTIFACTS order inside
    # one task, which is also the order phase D reads them back in; 17 892 tasks
    # over ten threads is parallelism to spare, and the profile's ratio of in-task
    # time to phase wall (7.5x on stage 2) is what says so rather than an argument.
    #
    # ★ `tasks` keeps its per-artifact shape because phase D, accepted.txt and
    # every number in this file's tables are keyed on `(ci, ui, art)`. Only the
    # SCHEDULING is grouped.
    unit_groups = {}
    for t in tasks:
        unit_groups.setdefault(t[0][:2], []).append(t)
    unit_jobs = [unit_groups[k] for k in sorted(unit_groups)]
    art_names = [a for a, _ in ARTIFACTS]

    def do_unit(group):
        uc = UnitRefCache(ref_cache_path(ctx, group[0][4]) if group else None)
        uc.load()
        out = []
        for task in group:
            _, key, art, keep, written, work = task
            ours_bin, ref_bin = bins[art]
            out.append(compare_one(ctx, key, art, keep, ours_bin, ref_bin,
                                   written, work, uc))
            tick(len(tasks), 3000, "compare")
        _t = time.time()
        uc.store(art_names)
        _tick(ctx, "refstore", _t)
        return out

    _phase_t0 = time.time()
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        grouped = list(pool.map(do_unit, unit_jobs))
    flat_tasks = [t for g in unit_jobs for t in g]
    verdicts = [v for g in grouped for v in g]

    # ── phase D: accumulate in the loop's order ─────────────────────────────
    results = {}
    for task, (verdict, message) in zip(flat_tasks, verdicts):
        results[task[0]] = (verdict, message, task[1], task[3], task[5])

    split_fail_by_case = dict(split_failures)
    art_order = [a for a, _ in ARTIFACTS]
    by_case = {}
    for k in results:
        by_case.setdefault(k[0], []).append(k)

    for ci in range(len(selected)):
        if ci in split_fail_by_case:
            failures.append(split_fail_by_case[ci])
            continue
        keys = sorted(by_case.get(ci, ()),
                      key=lambda k: (k[1], art_order.index(k[2])))
        seen_units = []
        for k in keys:
            verdict, message, key, _keep, work = results[k]
            art = k[2]
            if verdict == "MATCH":
                counters[f"matched_{art}"] += 1
            elif verdict == "STALE":
                counters[f"matched_{art}"] += 1
                counters[f"stale_{art}"] += 1
                stales.append(f"{art}/{key}")
            elif verdict == "UNPORTED":
                counters[f"unported_{art}"] += 1
            elif verdict == "ACCEPTED":
                counters[f"accepted_{art}"] += 1
            elif verdict == "REFCRASH":
                counters[f"refcrash_{art}"] += 1
                refcrashes.append(message)
            else:
                # A TIMEOUT is a failure — the totals must not lose it — and also a
                # class of its own, so it is counted twice on purpose and the report
                # names both.
                if verdict == "TIMEOUT":
                    counters[f"timeout_{art}"] += 1
                counters[f"failed_{art}"] += 1
                failures.append(message)
            if art == "jsdoc":
                seen_units.append(work)
        for work in seen_units:
            try:
                if os.path.getsize(f"{work}/jsdoc.ref") > 0:
                    counters["jsdoc_bearing"] += 1
            except OSError:
                pass
            # Counted off the REFERENCE dump, so the number says what the corpus
            # contains rather than what this port answered.
            try:
                with open(f"{work}/ast.ref", "rb") as fh:
                    n = sum(1 for line in fh if line.startswith(b"J "))
                if n:
                    counters["js_diag_units"] += 1
                    counters["js_diag_lines"] += n
            except OSError:
                pass
            try:
                syms = binds = 0
                with open(f"{work}/symbols.ref", "rb") as fh:
                    for line in fh:
                        if line.startswith(b"s "):
                            syms += 1
                        elif line.startswith(b"B "):
                            binds += 1
                if syms:
                    counters["symbol_bearing"] += 1
                if binds:
                    counters["bind_diag_units"] += 1
                    counters["bind_diag_lines"] += binds
            except OSError:
                pass

    ctx.wall["compare"] = time.time() - _phase_t0

    # ── the results, for the report in run.sh ───────────────────────────────
    with open(f"{out}/counters.sh", "w") as fh:
        for k in sorted(counters):
            fh.write(f"{k}={counters[k]}\n")
        # ★ A cache whose hit rate is invisible is a cache nobody can debug — and
        # a MISS count that does not fall to zero on a second identical run is the
        # first sign that the key is picking up something it should not.
        # ★ OFF is its own value and not "0 hits". With TSCALY_NO_REFCACHE=1 the
        # cache is never consulted, so a miss count would read as a cache that
        # answered nothing rather than one that was not asked — the difference a
        # reader needs when a run is slower than expected.
        if ctx.profile is not None:
            tot = sum(ctx.profile.values())
            print("\n  --- TSCALY_PROFILE ---", file=sys.stderr)
            for k, v in sorted(ctx.wall.items()):
                print("  phase %-10s %8.1f s wall" % (k, v), file=sys.stderr)
            for k, v in sorted(ctx.profile.items(), key=lambda kv: -kv[1]):
                print("  in-task %-9s %8.1f s cpu-across-threads (%4.1f%%)"
                      % (k, v, v * 100.0 / tot if tot else 0), file=sys.stderr)
        if ctx.refcache is None:
            fh.write("refcache=off\n")
        else:
            fh.write(f"refcache_hits={ctx.ref_hits}\n")
            fh.write(f"refcache_misses={ctx.ref_misses}\n")
    with open(f"{out}/failures.txt", "w", errors="surrogateescape") as fh:
        for f in failures:
            fh.write(f + "\n")
    with open(f"{out}/stales.txt", "w") as fh:
        for s in stales:
            fh.write(s + "\n")
    with open(f"{out}/refcrashes.txt", "w", errors="surrogateescape") as fh:
        for r in refcrashes:
            fh.write(r + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
