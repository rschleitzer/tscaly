#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# frontier.sh — HOW MUCH IS LEFT, and it answers a different question from stops.sh.
#
# ★★★ WHY IT EXISTS. `stops.sh` ranks CHAPTERS by how often the walk arrives; this ranks
# them by how many UNITS WOULD COMPLETE if they were ported. Those are not the same
# objective and the difference is measurable: slices 96 through 108 each removed the
# largest row at stage 2, and the CHECKER YARDSTICK did not move once in thirteen slices
# — because a unit's type dump matches only when EVERY wall it hits is gone, and the
# largest ROW is usually not one of the walls the stuck units share.
#
# ★★★ AND IT IS NOT A COUNTDOWN. A slice removes one chapter and REVEALS others: slice
# 108 removed `is-untyped-function-call` and added `infer-type-arguments` and
# `report-call-resolution-errors`, a net +1 on the frontier. So the chapter count is the
# current FRONTIER, never a number of slices remaining, and §3.5v's rule applies — the
# cause generalises, the magnitude does not.
#
# Usage (needs a run.sh tree; TSCALY_STAGE=2 for the whole submodule corpus):
#   packages/tscaly/tests/frontier.sh
set -u
cd "$(dirname "$0")/../../.."
PKG=packages/tscaly
BIN=${BIN:-$PKG/tests/out/tscaly_types}
LIMIT=${LIMIT:-3}

if [ ! -d "$PKG/tests/out/cases" ]; then
  echo "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first." >&2
  exit 2
fi

W=$(mktemp -d -t tscaly-frontier); trap 'rm -rf "$W"' EXIT
find "$PKG/tests/out/cases" -path '*/units/*' -type f \
     \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
        -o -name '*.mjs' -o -name '*.cjs' -o -name '*.mts' \) | sort > "$W/units.txt"

# ★ NUL-delimited pairing, for §3.5eu finding nine's reason: one stage-2 unit's path
# contains a SPACE, and an `xargs -n 2` pairing that shifts redirects the dumper's
# stdout INTO a corpus file.
i=0; mkdir -p "$W/o"
while IFS= read -r u; do
  printf '%s\0%s\0' "$u" "$(printf '%s/o/%06d' "$W" "$i")"; i=$((i+1))
done < "$W/units.txt" > "$W/pairs"
LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c \
  'perl -e "alarm $LIMIT; exec @ARGV" "$0" --stops "$1" > "$2" 2>/dev/null' \
  "$BIN" < "$W/pairs"

python3 - "$W/o" <<'PY'
import sys, os, glob, collections
d = sys.argv[1]
sets = []
for f in glob.glob(os.path.join(d, '*')):
    s = set()
    for line in open(f, errors='replace'):
        if line.startswith('S '):
            parts = line.split()
            if len(parts) >= 3:
                s.add((parts[1], parts[2]))
            elif len(parts) >= 2:
                s.add((parts[1], ''))
    sets.append(s)
n = len(sets)

# ★★★ TWO GRANULARITIES, BECAUSE ONE OF THEM LIES IN A WAY THE READER CANNOT SEE.
# A stop's TAG is a function; its ARGUMENT is usually the node KIND. So a tag like
# `type-of-node` is a DISPATCH with an arm per kind, several of which are chapters of
# their own — grouping by tag credits the whole dispatch to one slice and over-states
# it, while grouping by (tag, argument) splits a single chapter across its kinds and
# under-states it. Neither is the truth; the pair brackets it, which is why both curves
# are printed.
GRAN = os.environ.get('FRONTIER_GRAN', 'tag')
if GRAN == 'row':
    sets = [set(x for x in s) for s in sets]
else:
    sets = [set(t for t, _a in s) for s in sets]
tags = collections.Counter()
for s in sets:
    for t in s:
        tags[t] += 1
per = sorted(len(s) for s in sets)
done = sum(1 for s in sets if not s)
def name(t):
    return t if isinstance(t, str) else (t[0] + ' ' + t[1])
print("frontier — how much of the checker is left, by UNITS COMPLETED")
print("  granularity              %s   (FRONTIER_GRAN=tag|row)" % GRAN)
print("  units swept              %d" % n)
print("  units that COMPLETE now  %d" % done)
print("  distinct CHAPTERS left   %d" % len(tags))
if n:
    print("  chapters per unit        median %d, mean %.1f, p90 %d, max %d" % (
        per[n // 2], sum(per) / float(n), per[int(n * 0.9)], per[-1]))
print()
print("  ── the 15 chapters that would complete the most units ──")
# Greedy by marginal completions, which is the objective a slice should optimise.
gone = set()
remaining = set(tags)
for _ in range(15):
    best, gain = None, -1
    base = sum(1 for s in sets if not (s - gone))
    for t in remaining:
        g = sum(1 for s in sets if not (s - (gone | {t}))) - base
        if g > gain:
            best, gain = t, g
    if best is None:
        break
    gone.add(best); remaining.discard(best)
    print("    +%-5d %-52s (hit by %d units)" % (gain, name(best), tags[best]))
print()
print("  ── the completion CURVE, chapters taken in that greedy order ──")
order = []
gone = set(); remaining = set(tags)
while remaining:
    best, gain = None, -1
    base = sum(1 for s in sets if not (s - gone))
    for t in remaining:
        g = sum(1 for s in sets if not (s - (gone | {t}))) - base
        if g > gain:
            best, gain = t, g
    order.append(best); gone.add(best); remaining.discard(best)
    if len(order) > 200:
        order.extend(sorted(remaining)); break
gone = set()
for K in (0, 5, 10, 20, 40, 80, 120, len(order)):
    gone = set(order[:K])
    c = sum(1 for s in sets if not (s - gone))
    print("    %4d chapters -> %5d of %d units complete  (%.0f%%)" % (K, c, n, 100.0 * c / n))
print()
print("  ★ Read this as a SHAPE and never as a countdown: a slice removes one chapter")
print("    and reveals others (slice 108 was net +1). The rank is what a slice should")
print("    be chosen by; the count is not a number of slices remaining.")
PY
