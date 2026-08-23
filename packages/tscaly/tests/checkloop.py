#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# checkloop.py — the UNIT LOOP of walkcheck and diagcheck, in ONE process and on
# every core.
#
# ★★★ WHY IT EXISTS, and it is compare.py's argument arriving a second time. That
# module was written because the CASE loop was ~22 000 shell processes at ~3 ms of
# fork/exec apiece to perform 2 502 comparisons, at 5–20 % CPU (77.5 s -> 11.0 s).
# walkcheck.sh and diagcheck.sh were written later, in bash, and re-introduced the
# same shape one level down: per unit they ran an `awk` or a `grep`, the dumper,
# a `grep -c`, a `cmp` — and diagcheck ran a **python3 heredoc**, i.e. a fresh
# interpreter, once per unit. Measured on this tree: the dumper answers a unit in
# **5.3 ms** warm (100 units in 0.53 s) while diagcheck spent **~22 ms** on it, so
# roughly three quarters of both instruments was the loop around them.
#
# ★★★ AND PARALLELISM IS SAFE HERE FOR THE PRECISE REASON BATCHING IS NOT.
# TESTPLAN's *The cost of the runner* records the one lever that was refused: a
# batch-mode dumper would share process state across units and WOULD change what
# is measured. Running the same one-process-per-unit calls on N cores changes
# nothing about any single call — each unit still gets a fresh process, fresh
# arena, fresh everything. The property that made batching unsafe is exactly the
# property that survives a pool.
#
# ★★ WHAT MUST NOT MOVE, and what the two callers assert against the old
# implementation: the counters, the summary text, the ORDER and content of
# failures.txt, and the exit code. The order is why results are collected per unit
# and written in manifest order at the end rather than as they finish — a report
# whose line order depends on scheduling is a report nobody can diff.
#
# ★ The pool is threads, not processes: every unit's work is a `subprocess.run`,
# which releases the GIL for its whole duration, and the comparison either side of
# it is a few string operations. A process pool would pay fork cost to avoid a
# lock nothing holds.

import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

SUFFIXES = (".ts", ".mts", ".cts", ".tsx", ".jsx", ".js", ".cjs", ".mjs", ".json")


def read_manifest(path):
    rows = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) < 3 or not parts[0]:
                continue
            rows.append((parts[0], parts[1], parts[2]))
    return rows


def ref_lines(path, mode):
    # diagcheck reads the reference's C lines; walkcheck rewrites its T lines into
    # the W shape the dumper prints. Both are the awk/grep the shell ran per unit.
    # ★ The prefix test comes before the split, so an uninteresting line costs one
    # comparison instead of a tokenisation. It is strictly less work and its effect
    # was NOT measurable: this instrument reads ~220 MB of reference dumps, so its
    # wall time is decided by the PAGE CACHE — timings of the UNCHANGED code spanned
    # 4 s to 128 s depending on what the box had just done. ★That replaces a comment
    # which claimed the change was worth 60 s, a number taken from two runs in
    # different cache states. **On a box whose I/O state you are not controlling,
    # one timing is not a measurement** — the steady-state figures in CLAUDE.md are
    # the minimum of three alternating rounds for exactly this reason.
    out = []
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            if mode == "diags":
                for line in fh:
                    if line.startswith("C "):
                        out.append(line.rstrip("\n"))
            else:
                for line in fh:
                    if line.startswith("T "):
                        f = line.split(" ", 4)
                        if len(f) >= 4:
                            out.append("W %s %s %s" % (f[1], f[2], f[3]))
    except OSError:
        pass
    return out


def is_subsequence(ours, ref):
    it = iter(ref)
    return all(any(r == o for r in it) for o in ours)


def unified_diff_head(ref, ours, n):
    # `diff <ref> <ours> | head -n`, in the ed-script format BSD/GNU diff share for
    # the default output — transcribed rather than replaced by difflib's unified
    # format, because the committed failure reports are read against it.
    import difflib

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
    return lines[:n]


def main():
    mode = sys.argv[1]              # "diags" | "walk"
    cases = sys.argv[2]
    binary = sys.argv[3]
    work = sys.argv[4]
    filt = sys.argv[5] if len(sys.argv) > 5 else ""
    tree_bin = sys.argv[6] if len(sys.argv) > 6 else ""
    flag = "--diags" if mode == "diags" else "--walk"

    jobs = []                       # (case_key, idx, unit_path, ref)
    other = 0
    skipped = 0

    manifests = sorted(
        os.path.join(cases, d, "units.manifest") for d in os.listdir(cases)
        if os.path.isfile(os.path.join(cases, d, "units.manifest"))
    )
    for manifest in manifests:
        case_dir = os.path.dirname(manifest)
        case_key = os.path.basename(case_dir)
        if filt and filt not in case_key:
            continue
        for idx, unit_path, unit_name in read_manifest(manifest):
            if not unit_name.lower().endswith(SUFFIXES):
                other += 1
                continue
            ref = os.path.join(case_dir, idx, "types.ref")
            err = ref + ".err"

            def nonempty(p):
                try:
                    return os.path.getsize(p) > 0
                except OSError:
                    return False

            if not nonempty(ref) and nonempty(err):
                skipped += 1
                continue
            if not os.path.isfile(unit_path):
                skipped += 1
                continue
            jobs.append((case_key, idx, unit_path, ref))

    # ★★★ THE SIDECAR IS READ WHERE IT EXISTS AND THE PROCESS IS SPAWNED WHERE IT
    # DOES NOT (slice 58). run.sh's `types` dump now runs the dumper in
    # `--sections` mode and drops the two instrument answers beside the artifact,
    # so the 17 892 processes this loop used to start are 17 892 file reads — the
    # parse and the bind behind each one had already been performed in the same
    # minute. Proven equal over the whole corpus before the switch.
    #
    # ★★ THE FALLBACK IS NOT A CONVENIENCE. The sidecar is missing whenever this
    # instrument is pointed at a BIN other than the one that produced the tree —
    # which is exactly what every control-battery row does — so the spawn path
    # stays, and it stays the DEFAULT whenever `BIN` is not the tree's own dumper.
    # A cached answer from the wrong binary is the one failure this whole file
    # exists to make impossible.
    sidecar_name = "types.diags" if mode == "diags" else "types.walk"
    use_sidecar = os.path.realpath(binary) == os.path.realpath(tree_bin) if tree_bin else False

    def run(job):
        case_key, idx, unit_path, ref = job
        if use_sidecar:
            side = os.path.join(os.path.dirname(ref), sidecar_name)
            try:
                with open(side, "r", errors="replace") as fh:
                    return job, 0, fh.read(), ""
            except OSError:
                pass
        p = subprocess.run([binary, flag, unit_path], capture_output=True, text=True)
        return job, p.returncode, p.stdout, p.stderr

    workers = min(32, (os.cpu_count() or 4))
    with ThreadPoolExecutor(max_workers=workers) as pool:
        results = list(pool.map(run, jobs))

    units = len(jobs)
    matched = failed = speaking = lines = 0
    report = []

    for (case_key, idx, unit_path, ref), rc, out, err in results:
        if rc != 0:
            failed += 1
            what = "our check" if mode == "diags" else "our walk"
            report.append("=== %s[%s] — %s exited %d" % (case_key, idx, what, rc))
            report += err.splitlines()[:5]
            continue
        ours = out.splitlines()
        theirs = ref_lines(ref, mode)
        if mode == "diags":
            ours_c = [l for l in ours if l.startswith("C ")]
            if ours_c:
                speaking += 1
                lines += len(ours_c)
            if is_subsequence(ours_c, theirs):
                matched += 1
            else:
                failed += 1
                report.append("=== %s[%s] — %s" % (case_key, idx, unit_path))
                report.append("--- ours (a prefix of the check, sorted)")
                report += ours_c[:20]
                report.append("--- the reference's C lines")
                report += theirs[:20]
        else:
            if ours == theirs:
                matched += 1
            else:
                failed += 1
                report.append("=== %s[%s] — %s" % (case_key, idx, unit_path))
                report += unified_diff_head(theirs, ours, 20)

    os.makedirs(work, exist_ok=True)
    with open(os.path.join(work, "failures.txt"), "w", encoding="utf-8") as fh:
        for line in report:
            fh.write(line + "\n")

    # The counters the shell wrapper prints, one per line, so it stays the owner of
    # the prose.
    print("units %d" % units)
    print("matched %d" % matched)
    print("failed %d" % failed)
    print("skipped %d" % skipped)
    print("other %d" % other)
    print("speaking %d" % speaking)
    print("lines %d" % lines)
    return 0


if __name__ == "__main__":
    sys.exit(main())
