#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# checkloop.py — the UNIT LOOP of walkcheck.sh, diagcheck.sh and stops.sh.
#
# One Python process over the store (harness.Store) instead of a shell loop over an
# artifact tree — the 2026-08-25 lesson (slice 58) that a per-unit python3 heredoc
# costs more than the unit, and the 2026-09-02 one that a per-unit FILE does too.
#
#   diags   our `C` lines must be a SUBSEQUENCE of the reference's (the port may be
#           silent where the reference speaks, never the reverse, never reordered)
#   walk    our `W` node list must EQUAL the one derived from the reference's T lines
#   stops   every `S` event of a unit, checked against the UNPORTED tag the run
#           recorded for it, and collected for the histograms
#
# The reference side comes from the store; our side comes from the store's own
# sidecars (`types.diags` / `types.walk`, written by the run) when the binary IS the
# run's binary, and from ONE `tscaly_types <flag> --batch` process per chunk
# otherwise (harness.run_batch) — never from a process per unit.
#
# usage: checkloop.py <diags|walk|stops> <out dir> <binary> <work dir> [filter] [tree binary]
# prints `name value` lines for the caller to eval; writes <work>/failures.txt
# (and events.txt + units.txt for stops).

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import harness as H  # noqa: E402

UNIT_TIMEOUT = float(os.environ.get("TSCALY_UNIT_TIMEOUT", "10"))


def ref_lines(data: bytes, mode):
    out = []
    for line in data.decode("utf-8", "replace").split("\n"):
        if mode == "diags":
            if line.startswith("C "):
                out.append(line)
        elif line.startswith("T "):
            f = line.split(" ", 4)
            if len(f) >= 4:
                out.append("W %s %s %s" % (f[1], f[2], f[3]))
    return out


def is_subsequence(ours, ref):
    it = iter(ref)
    return all(any(r == o for r in it) for o in ours)


def main():
    mode = sys.argv[1]
    out_dir = sys.argv[2]
    binary = sys.argv[3]
    work = sys.argv[4]
    filt = sys.argv[5] if len(sys.argv) > 5 else ""
    tree_bin = sys.argv[6] if len(sys.argv) > 6 else ""
    flag = {"diags": "--diags", "walk": "--walk", "stops": "--stops"}[mode]

    store = H.Store.open(out_dir)
    if store is None:
        print("checkloop.py: no store at %s — run tests/run.sh first." % H.store_path(out_dir), file=sys.stderr)
        return 2
    types = store.artifacts_of("types")

    jobs = []           # (case_key, idx, path, content, artifact row)
    other = skipped = 0
    for ci, idx, case_key, key, uname, path, content in store.units(compared_only=False, filt=filt):
        if not uname.lower().endswith(H.SUFFIXES):
            other += 1
            continue
        a = types.get((ci, idx))
        if a is None or (not a["ref"] and a["ref_err"]):
            skipped += 1
            continue
        jobs.append((case_key, str(idx), path, content, a))

    sidecar = {"diags": "diags", "walk": "walk", "stops": None}[mode]
    use_sidecar = (sidecar is not None and tree_bin
                   and os.path.realpath(binary) == os.path.realpath(tree_bin))
    answers = {}
    if use_sidecar:
        for case_key, idx, path, content, a in jobs:
            side = a.get(sidecar)
            answers[path] = (0, side, b"") if side is not None else None
    todo = [(path, content) for case_key, idx, path, content, a in jobs if answers.get(path) is None]
    if todo:
        got = H.run_batch(binary, flag, todo, os.path.join(work, "chunks"), min(32, os.cpu_count() or 4), UNIT_TIMEOUT)
        answers.update(got)

    units = len(jobs)
    matched = failed = speaking = lines = 0
    report, event_rows, unit_rows = [], [], []
    for case_key, idx, path, content, a in jobs:
        rc, out, err = answers.get(path, (1, b"", b"no answer"))
        if rc != 0:
            failed += 1
            what = "our check" if mode == "diags" else "our walk"
            report.append("=== %s[%s] — %s exited %s" % (case_key, idx, what,
                          "TIMEOUT after %gs" % UNIT_TIMEOUT if rc == H.TIMED_OUT else rc))
            report += err.decode("utf-8", "replace").splitlines()[:5]
            continue
        ours = out.decode("utf-8", "replace").splitlines()
        if mode == "stops":
            stops = [l for l in ours if l.startswith("S ")]
            recorded = None
            for line in (a["ours"] or b"").decode("utf-8", "replace").split("\n"):
                if line.startswith("UNPORTED "):
                    f = line.split()
                    if len(f) >= 4:
                        recorded = "S %s %s" % (f[2], f[3])
                    break
            if not stops and recorded is None:
                matched += 1
            elif stops and recorded is not None and stops[0] == recorded:
                matched += 1
                speaking += 1
                lines += len(stops)
                for l in stops:
                    event_rows.append(l[2:])
                for l in sorted(set(l[2:] for l in stops)):
                    unit_rows.append("%s[%s] %s" % (case_key, idx, l))
            elif not stops and recorded is not None:
                other += 1
            else:
                failed += 1
                report.append("=== %s[%s] — %s" % (case_key, idx, path))
                report.append("--- first logged stop: %s" % (stops[0] if stops else "(none)"))
                report.append("--- recorded by the work list: %s" % (recorded or "(none)"))
            continue
        theirs = ref_lines(a["ref"] or b"", mode)
        if mode == "diags":
            ours_c = [l for l in ours if l.startswith("C ")]
            if ours_c:
                speaking += 1
                lines += len(ours_c)
            if is_subsequence(ours_c, theirs):
                matched += 1
            else:
                failed += 1
                report.append("=== %s[%s] — %s" % (case_key, idx, path))
                report.append("--- ours (a prefix of the check, sorted)")
                report += ours_c[:20]
                report.append("--- the reference's C lines")
                report += theirs[:20]
        else:
            if ours == theirs:
                matched += 1
            else:
                failed += 1
                report.append("=== %s[%s] — %s" % (case_key, idx, path))
                report += H.diff_lines(theirs, ours, 20)

    os.makedirs(work, exist_ok=True)
    with open(os.path.join(work, "failures.txt"), "w", encoding="utf-8") as fh:
        for line in report:
            fh.write(line + "\n")
    if mode == "stops":
        with open(os.path.join(work, "events.txt"), "w", encoding="utf-8") as fh:
            for line in event_rows:
                fh.write(line + "\n")
        with open(os.path.join(work, "units.txt"), "w", encoding="utf-8") as fh:
            for line in unit_rows:
                fh.write(line + "\n")
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
