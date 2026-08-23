#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# walkcheck.sh — the cross-check for the TYPE WALK (slice 47).
#
# ★★★ WHY IT IS A GATE OF ITS OWN, and it is the same argument PathCheck and
# NumCheck make one dimension down: an unexercised arm is indistinguishable from a
# correct one. The fifth yardstick compares a unit only when BOTH of its sections
# agree, and the C section (the checker's diagnostics) is complete only when the
# check of every statement in the unit is ported — so on the day the checker
# skeleton lands, 1 030 of 1 038 units never reach the type walk at all. Everything
# the walk is made of would therefore be code no control could turn red:
#
#   forEachASTNode's two Reparsed conditions        (TypeDump.walk)
#   skipForType's four exclusions                   (TypeDump.skip_for_type)
#   ast.IsPartOfTypeNode and its two helpers        (twenty arms)
#   ast.GetMeaningFromDeclaration                   (six arms and a default)
#   the nameless type-only import clause guard      (the oracle's own exclusion)
#
# All five are transcribed from the reference — the walk's exclusions are the
# yardstick's CONTRACT, since GetTypeAtLocation at every node nil-dereferences
# inside the checker — and a transcription nothing measures is a guess.
#
# So this instrument asks the ONE question the walk answers, over the whole corpus:
# WHICH NODES does the type walk ask about? Our side prints that list in `--walk`
# mode and the reference's own dump already carries it, in the first three fields
# of every T line.
#
#   ours       tscaly_types --walk <unit>      → `W <kind> <pos> <end>`
#   reference  tests/out/cases/*/N/types.ref   → `T <kind> <pos> <end> <type>`
#
# ★ What it deliberately does NOT check is the TYPE. The third field of a T line
# has no counterpart in a W line, because deciding whether a type is RIGHT is the
# yardstick's job and an instrument that pretended to answer it would be worse than
# none — tests/checktypes.py draws the same boundary from the other side.
#
# ★★ IT NEEDS NO ORACLE BUILD AND NO SUBMODULE. Both inputs are artifacts run.sh
# has already produced: the split units and the reference dumps under
# tests/out/cases. That is what makes it cheap enough to run per slice — and it is
# also its precondition, so it says so rather than silently measuring a stale tree.
#
# Usage:  packages/tscaly/tests/walkcheck.sh [filter]
#         TSCALY_STAGE=2 packages/tscaly/tests/run.sh && packages/tscaly/tests/walkcheck.sh
#         (the stage is whatever the last run.sh left in tests/out)

set -u

cd "$(dirname "$0")/../../.."
REPO=$(pwd)

PKG=packages/tscaly
OUT=$PKG/tests/out
CASES=$OUT/cases
FILTER=${1:-}
BIN=${BIN:-$OUT/tscaly_types}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

if [ ! -d "$CASES" ]; then
  red "no artifact tree at $CASES"
  echo "  packages/tscaly/tests/run.sh          # then run this"
  echo "Both inputs are that run's artifacts: the split units and the reference dumps."
  exit 1
fi

if [ ! -x "$BIN" ]; then
  red "no dumper at $BIN"
  echo "  packages/tscaly/tests/run.sh          # builds it"
  exit 1
fi

# ★★★ THE SCRATCH FILES CARRY THE PID, AND THAT IS NOT TIDINESS — IT IS A DEFECT
# THIS INSTRUMENT HAD (slice 58). `ref.txt` and `ours.txt` are rewritten once per
# unit, so TWO runs of this script against the same tree interleave their writes
# and every comparison after the first collision is between one run's reference
# and the other run's answer. Measured: a second run started while the first was
# still going reported **5 260 of 17 888 units differing**, with diffs that read
# exactly like a broken walk — whole node lists replaced, one line truncated
# mid-field — and the same command alone answered 17 888 / 17 888. The FAILURE
# DIRECTORY is per-run for the same reason; only the summary is shared, and it is
# written last.
#
# ★ It is the "shared scratch is a silent coupling" class the LSP suite paid for,
# turned one notch: there the collision was between two TESTS, here between two
# runs of one instrument — so nothing in the script names a second party and
# there is no fixture to isolate. What makes it findable at all is that a battery
# and a manual check are the ordinary way this gets used.
WORK=$OUT/walkcheck.$$
rm -rf "$WORK"
mkdir -p "$WORK"

: > "$WORK/failures.txt"
# ★★★ THE UNIT LOOP MOVED INTO ONE PYTHON PROCESS ON EVERY CORE (slice 58), and
# nothing about WHAT is measured moved with it — see tests/checkloop.py for the
# argument, and for why a POOL is safe where the batch-mode dumper TESTPLAN
# refused was not. Measured on this tree: the dumper answers a unit in 5.3 ms warm
# and this loop spent ~22 ms on it, because per unit the shell ran an awk or a
# grep, the dumper, a grep -c, a cmp — and, in diagcheck, a whole python3
# interpreter. The verdicts, the counters and failures.txt are byte-identical
# across the change; that check is the whole licence for it.

eval "$(python3 "$(dirname "$0")/checkloop.py" walk "$CASES" "$BIN" "$WORK" "$FILTER" \
        | sed 's/^\([a-z]*\) \(.*\)$/\1=\2/')" || {
  red "the unit loop failed"
  exit 2
}

echo
echo "walkcheck — the type walk's NODE LIST against the reference's own"
echo "  units compared     $units"
echo "  matched            $matched"
echo "  differing          $failed"
echo "  no reference list  $skipped   (the oracle could not answer the unit)"
echo "  not a source unit  $other   (the yardstick does not compare these either)"
if [ "$failed" != 0 ]; then
  echo
  head -60 "$WORK/failures.txt"
  echo
  red "WALKCHECK: $failed of $units units disagree — see $WORK/failures.txt"
  exit 1
fi
# ★ The per-run scratch directory is removed on a GREEN run and KEPT on a red
# one, because its whole content is then the report the last line points at.
rm -rf "$WORK"
green "WALKCHECK: OK"
