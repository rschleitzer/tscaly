#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# diagcensus.py — the checker's diagnostics counted BY CODE over the whole run,
# reference against ours, and it answers a question no per-unit instrument can.
#
# ★★★ WHY IT EXISTS (slice 200). `frontier.sh` ranks CHAPTERS by units they would
# complete and `triage.py` groups FAILING units by their first differing line. Once
# the frontier is down to twenty units, neither of them can see a rule the port has
# NEVER HAD: a diagnostic code we cannot emit at all shows up as one or two red units
# among a hundred, indistinguishable from a hundred unrelated causes, and nothing in
# the unit list says to look at those two. Counted by CODE it is unmistakable —
#
#     TS2321   ref   9   ours   0
#     TS2859   ref   2   ours   0
#
# — and those two zeroes were the relation's whole complexity budget, missing, which
# had also been costing the corpus five TIMEOUT rows and a 15.5 s answer on a
# sixteen-line file. **A code the port cannot emit AT ALL is invisible to a yardstick
# that scores units.**
#
# ★★ READ THE PER-UNIT COLUMN BEFORE BELIEVING A TOTAL. The largest delta in the same
# run was TS2589 at +45, and all 45 of it sat in ONE already-known unit. A corpus
# total is a sum over units and says nothing about how many units carry it, which is
# the difference between a rule and a bug. `--by-unit CODE` prints that column.
#
# Usage:  packages/tscaly/tools/diagcensus.py [--by-unit TSNNNN] [--min N]
#         (reads packages/tscaly/tests/out/run.db; TSCALY_STAGE=2 for the whole corpus)

import collections
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests"))
import harness as H  # noqa: E402


def codes(blob):
    out = collections.Counter()
    for line in (blob or b"").split(b"\n"):
        if line.startswith(b"C "):
            f = line.split(b" ")
            if len(f) >= 4:
                out[f[3].decode()] += 1
    return out


def main(argv):
    by_unit = None
    minimum = 1
    i = 1
    while i < len(argv):
        if argv[i] == "--by-unit":
            by_unit = argv[i + 1].removeprefix("TS")
            i += 2
        elif argv[i] == "--min":
            minimum = int(argv[i + 1])
            i += 2
        else:
            print(__doc__ or "", file=sys.stderr)
            return 2
    store = H.Store.open()
    if store is None:
        print("no run store — run tests/run.sh first.", file=sys.stderr)
        return 2
    names = {(ci, idx): cn for ci, idx, cn, key, un, p, c in store.units()}
    arts = store.artifacts_of("types")
    ref, ours = collections.Counter(), collections.Counter()
    carriers = collections.defaultdict(set)
    rows = []
    for (ci, idx), a in arts.items():
        r, o = codes(a["cut"]), codes(a["ours"])
        ref += r
        ours += o
        for c in set(r) | set(o):
            if r[c] != o[c]:
                carriers[c].add(names[(ci, idx)])
        if by_unit is not None and (r[by_unit] or o[by_unit]):
            rows.append((o[by_unit] - r[by_unit], r[by_unit], o[by_unit], a["verdict"], names[(ci, idx)]))

    if by_unit is not None:
        print("TS%s, per unit  (delta = ours - ref)" % by_unit)
        for d, r, o, v, n in sorted(rows, reverse=True):
            print("  %+4d  ref=%-4d ours=%-4d [%s] %s" % (d, r, o, v, n))
        return 0

    diff = [(ref[c] - ours[c], c) for c in set(ref) | set(ours) if ref[c] != ours[c]]
    diff.sort(key=lambda t: -abs(t[0]))
    print("diagnostics by CODE — reference against ours, %d units" % len(arts))
    print("  %-10s %7s %7s %8s  %s" % ("code", "ref", "ours", "delta", "units carrying it"))
    for d, c in diff:
        if abs(d) < minimum:
            continue
        flag = "   ← NEVER EMITTED" if ours[c] == 0 and ref[c] else ""
        print("  TS%-8s %7d %7d %+8d  %d%s" % (c, ref[c], ours[c], -d, len(carriers[c]), flag))
    print("  %-10s %7d %7d %+8d" % ("total", sum(ref.values()), sum(ours.values()),
                                    sum(ours.values()) - sum(ref.values())))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
