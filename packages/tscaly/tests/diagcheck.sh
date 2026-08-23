#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# diagcheck.sh — the cross-check for the CHECKER'S DIAGNOSTICS (slice 48).
#
# ★★★ WHY IT IS A GATE OF ITS OWN, and it is walkcheck.sh's argument turned
# around. That instrument exists because the C section gates the T section, so
# nothing of the type WALK is measured; this one exists because the same gate
# hides the C section's own machinery. A unit counts as matched only when BOTH
# sections agree, and the C half is complete only when the check of EVERY
# statement is ported — so on the day the first grammar arm lands, the dump of
# 1 031 of 1 040 units is suppressed and none of this is reachable by any control:
#
#   checkGrammarSourceFile's declare-modifier walk   (TS1046, and ast.IsDeclarationNode)
#   checkGrammarStatementInAmbientContext            (TS1036 and TS1183, and the once-bit)
#   grammarErrorOnFirstToken's SPAN                  (a scan, not the node's pos)
#   the parse-diagnostic suppression                 (a whole file's grammar checks)
#   DiagnosticList.sort_by_position                  (CompareDiagnostics)
#
# ── The relation it checks, and why it is a SUBSEQUENCE ──────────────────────
#
# Our side runs the check and prints the C section ALONE, whether or not the
# check reported (`tscaly_types --diags`). What comes out is a PREFIX of the
# check: the diagnostics found before it stopped. The reference's C lines are the
# whole check, sorted. So the sound relation is:
#
#     every line we print appears in the reference's C lines, IN ORDER
#
# ★★ AND THE "IN ORDER" IS NOT DECORATION — it is the only thing that measures
# the SORT. A subset test passes on a port that emits in discovery order; a
# subsequence test does not, because our lines are sorted among themselves and
# the reference's are sorted globally, so a wrongly ordered pair of ours cannot
# be embedded in theirs.
#
# ★★★ WHAT IT CANNOT CATCH, said plainly because an instrument whose scope is
# narrower than its claim is the trap it exists to prevent: a MISSING diagnostic.
# Printing nothing is a subsequence of anything, so a port that reports no grammar
# errors at all passes this every time. That half is the yardstick's, and it
# arrives when a unit's check completes. What this catches is a diagnostic we
# invent, one at the wrong span, one with the wrong code, and two in the wrong
# order — which is every failure mode the five items above have.
#
# ★ It also reports the number of units on which we print ANYTHING, because a
# green run over an all-empty corpus is the same green as a green run that
# measured something, and only the count tells them apart.
#
# ★★ IT NEEDS NO ORACLE BUILD AND NO SUBMODULE, exactly as walkcheck.sh does not:
# both inputs are artifacts a run.sh has already produced — the split units and
# the reference dumps under tests/out/cases. That is also its precondition, so it
# says so rather than silently measuring a stale tree.
#
# Usage:  packages/tscaly/tests/diagcheck.sh [filter]
#         TSCALY_STAGE=2 packages/tscaly/tests/run.sh && packages/tscaly/tests/diagcheck.sh
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
WORK=$OUT/diagcheck.$$
rm -rf "$WORK"
mkdir -p "$WORK"

: > "$WORK/failures.txt"
# ★★★ THE UNIT LOOP MOVED INTO ONE PYTHON PROCESS ON EVERY CORE (slice 58), and
# nothing about WHAT is measured moved with it — see tests/checkloop.py for the
# argument, and for why a POOL is safe where the batch-mode dumper TESTPLAN
# refused was not. This instrument was the worse of the two: it ran a python3
# HEREDOC per unit, i.e. a fresh interpreter, to answer a subsequence test over a
# handful of lines. The verdicts, the counters and failures.txt are byte-identical
# across the change; that check is the whole licence for it.

eval "$(python3 "$(dirname "$0")/checkloop.py" diags "$CASES" "$BIN" "$WORK" "$FILTER" \
        | sed 's/^\([a-z]*\) \(.*\)$/\1=\2/')" || {
  red "the unit loop failed"
  exit 2
}

echo
echo "diagcheck — the checker's diagnostics as a SUBSEQUENCE of the reference's"
echo "  units compared     $units"
echo "  consistent         $matched"
echo "  differing          $failed"
echo "  units we speak on  $speaking   ($lines diagnostics; a green run over an"
echo "                     all-empty corpus would look the same without this)"
echo "  no reference list  $skipped   (the oracle could not answer the unit)"
echo "  not a source unit  $other   (the yardstick does not compare these either)"
if [ "$failed" != 0 ]; then
  echo
  head -60 "$WORK/failures.txt"
  echo
  red "DIAGCHECK: $failed of $units units disagree — see $WORK/failures.txt"
  exit 1
fi
# ★ The per-run scratch directory is removed on a GREEN run and KEPT on a red
# one, because its whole content is then the report the last line points at.
rm -rf "$WORK"
green "DIAGCHECK: OK"
