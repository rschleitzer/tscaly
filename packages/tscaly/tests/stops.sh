#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# stops.sh — the STOP HISTOGRAM (slice 75).
#
# ★★★ WHY IT EXISTS, AND IT IS NOT A CONVENIENCE. `Checker.record_unported` is
# FIRST-WINS while the walk deliberately continues, so the histogram triage.py
# prints is a histogram of FIRSTS. Every later stop in the same unit is invisible
# there — which means a row that many units reach reads as **0** whenever they all
# stop somewhere else first, and a row of 0 is indistinguishable from a row nothing
# reaches at all.
#
# That is not hypothetical and it cost a slice's premise. Slice 74 chose its
# successor off the work list and wrote that the extends chapter's *"own first wall
# is isConstructorType"*. Measured over the same stage-1 corpus with this
# instrument:
#
#   class-extends-heritage-clause      0 in the work list   27 units / 46 arrivals here
#   the wall those arrivals actually hit:
#       check-identifier                     78 events   (85 %)
#       check-call-expression                 6
#       check-object-literal                  4
#       is-constructor-type                   2   ← the predicted one
#       check-property-access-expression      2
#
# So the prediction was true of 2 of 92 and the chapter is gated on `checkIdentifier`
# — and behind that on a globals table this port does not build and a lib file it
# does not load (§3.11). **None of that is visible in a histogram of firsts.**
#
# ── what it measures ────────────────────────────────────────────────────────
#
#   ours   tscaly_types --stops <unit>   → `S <tag> <detail>`, one per stop, IN ORDER
#
# Two aggregations, because they answer different questions and the difference is
# the point: EVENTS says how often the walk arrives at a stop, UNITS says how much
# of the corpus a chapter would unblock. A stop inside a per-declaration loop has a
# large event count and may sit in one unit.
#
# ★★★ THERE IS NO REFERENCE HERE AND IT NEEDS NONE — THE GATE IS INTERNAL. The log
# and the work list are two views of one event stream, so the unit's FIRST `S` line
# must be the tag `record_unported` kept, and a unit with no stops must carry no
# UNPORTED line. That is what makes the instrument self-refuting rather than
# self-confirming: collect the log anywhere but in record_unported, or out of order,
# and this disagrees. See checkloop.py's `stops` arm.
#
# ★★★ AND WHAT THE GATE DOES **NOT** CATCH, MEASURED RATHER THAN REASONED — TWO
# NEGATIVE CONTROLS RUN THE DAY IT LANDED:
#
#   A  the logged tag replaced by a constant   →  RED 1 258 of 1 296.  The gate bites.
#   B  the append moved INSIDE the first-wins  →  GREEN 0 disagreeing, and
#      guard, so only the first stop is kept      `stop events` 7 424 → 1 258
#
# So the gate proves the log's FIRST entry and its PRESENCE, and it is BLIND TO
# TRUNCATION — of course it is: a truncated log's first entry is still the right
# one. What catches B is the EVENT COUNT, which is why this script prints it instead
# of folding it away, and the signature is unmistakable: under truncation the event
# count equals the speaking-unit count exactly. **An instrument owes the list of
# what its own gate cannot see, or the green is read as more than it is.**
#
# ★★★ AND THE THIRD THING IT COULD NOT SEE WAS NOT ON THAT LIST — SLICE 76 FOUND IT
# BY MOVING FOUR UNITS INTO A BUCKET NOBODY HAD PRINTED. The stop mode returned
# straight after `get_diagnostics()`, so a unit whose CHECK completes and whose DUMP
# stops logged nothing at all; checkloop.py filed the combination under `other` and
# explained it as *"the checker never ran"*. All 32 read `UNPORTED 0 type-of-node
# <kind>` — a tag only the dump walk raises — and not one was a parse or a bind
# stop. `TypeDump.write_stops` runs the walk now: the gate went 1 264/1 296 to
# 1 296/1 296 and `other` to 1. ★★What it BUYS is the more useful number, because
# those 32 are the units whose CHECK IS COMPLETE and whose only remaining wall is
# one arm of `getTypeOfNode` — the closest thing this port has to a frontier, and
# invisible in every histogram until now.
#
# ★★ THE CHECKSUM THE LOG ITSELF OWES is that the five artifacts stay byte-identical
# with it in place — it is collected unconditionally, so it must change nothing that
# is measured. Asserted by run.sh going green, and verified once directly on the
# whole tree the day it landed.
#
# ★ IT DOES NOT NEED THE ORACLE OR THE SUBMODULE, only a run.sh tree: the split
# units and each unit's own `types.ours`. That is also its precondition, so it says
# so rather than silently measuring a stale tree.
#
# Usage:  packages/tscaly/tests/stops.sh [filter]
#         TSCALY_STAGE=2 packages/tscaly/tests/run.sh && packages/tscaly/tests/stops.sh
#         (the stage is whatever the last run.sh left in tests/out)

set -u

cd "$(dirname "$0")/../../.."

PKG=packages/tscaly
OUT=$PKG/tests/out
CASES=$OUT/cases
FILTER=${1:-}
TOP=${TOP:-25}
BIN=${BIN:-$OUT/tscaly_types}

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

if [ ! -f "$OUT/run.db" ]; then
  red "no run store at $OUT/run.db"
  echo "  packages/tscaly/tests/run.sh          # then run this"
  exit 1
fi

if [ ! -x "$BIN" ]; then
  red "no dumper at $BIN"
  echo "  packages/tscaly/tests/run.sh          # builds it"
  exit 1
fi

# Per-run scratch, carrying the PID for the reason walkcheck.sh's own note gives at
# length: two runs of one instrument against one tree are the ordinary way this gets
# used, and a shared scratch file makes the second one compare halves of both.
WORK=$OUT/stops.$$
rm -rf "$WORK"
mkdir -p "$WORK"

eval "$(python3 "$PKG/tests/checkloop.py" stops "$OUT" "$BIN" "$WORK" "$FILTER" "" \
        | sed 's/^\([a-z]*\) \(.*\)$/\1=\2/')" || {
  red "the unit loop failed"
  exit 2
}

echo
echo "stops — EVERY stop of every unit, not just the first-wins one"
echo "  units compared     $units"
echo "  agreeing with the work list  $matched"
echo "  DISAGREEING        $failed"
echo "  units with a stop  $speaking"
echo "  stop events        $lines"
echo "  parse/bind stop    $other   (the checker never ran, so the log is empty)"
echo "  no reference dump  $skipped"

if [ "$failed" != 0 ]; then
  echo
  head -40 "$WORK/failures.txt"
  echo
  red "STOPS: $failed of $units units disagree with the work list — see $WORK/failures.txt"
  exit 1
fi

# The two histograms. Recomputed here from the per-unit logs the loop wrote, so
# there is no second copy of the aggregation rule.
if [ -s "$WORK/events.txt" ]; then
  echo
  echo "── by EVENT — how often the walk arrives (top $TOP) ──"
  sort "$WORK/events.txt" | uniq -c | sort -rn | head -"$TOP" | sed 's/^/  /'
  echo
  echo "── by UNIT — how much of the corpus a chapter would unblock (top $TOP) ──"
  sort -u "$WORK/units.txt" | cut -d' ' -f2- | sort | uniq -c | sort -rn | head -"$TOP" | sed 's/^/  /'
fi

rm -rf "$WORK"
green "STOPS: OK — the log agrees with the work list on all $units units"
