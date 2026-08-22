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

WORK=$OUT/diagcheck
rm -rf "$WORK"
mkdir -p "$WORK"

units=0
matched=0
failed=0
skipped=0
other=0
speaking=0
lines=0
: > "$WORK/failures.txt"

for manifest in "$CASES"/*/units.manifest; do
  case_dir=$(dirname "$manifest")
  case_key=$(basename "$case_dir")
  if [ -n "$FILTER" ]; then
    case "$case_key" in
      *"$FILTER"*) ;;
      *) continue ;;
    esac
  fi
  while IFS=$'\t' read -r idx unit_path unit_name; do
    [ -n "${idx:-}" ] || continue
    # The same suffix filter compare.py's classify_unit applies, for walkcheck's
    # reason: a corpus case may hold a unit that is not a TypeScript source at all
    # and the yardstick does not compare it, so neither may this.
    case $(printf '%s' "$unit_name" | tr 'A-Z' 'a-z') in
      *.ts|*.mts|*.cts|*.tsx|*.jsx|*.js|*.cjs|*.mjs|*.json) ;;
      *) other=$((other + 1)); continue ;;
    esac
    ref="$case_dir/$idx/types.ref"
    if [ ! -s "$ref" ] && [ -s "$case_dir/$idx/types.ref.err" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    [ -f "$unit_path" ] || { skipped=$((skipped + 1)); continue; }
    units=$((units + 1))
    grep '^C ' "$ref" > "$WORK/ref.txt" 2>/dev/null || : > "$WORK/ref.txt"
    "$BIN" --diags "$unit_path" > "$WORK/ours.txt" 2> "$WORK/ours.err"
    rc=$?
    if [ "$rc" != 0 ]; then
      failed=$((failed + 1))
      {
        echo "=== $case_key[$idx] — our check exited $rc"
        head -5 "$WORK/ours.err"
      } >> "$WORK/failures.txt"
      continue
    fi
    n=$(grep -c '^C ' "$WORK/ours.txt" || true)
    if [ "$n" != 0 ]; then
      speaking=$((speaking + 1))
      lines=$((lines + n))
    fi
    if python3 - "$WORK/ours.txt" "$WORK/ref.txt" <<'PY'
import sys
ours = [l for l in open(sys.argv[1]) if l.startswith("C ")]
ref  = [l for l in open(sys.argv[2]) if l.startswith("C ")]
it = iter(ref)
sys.exit(0 if all(any(r == o for r in it) for o in ours) else 1)
PY
    then
      matched=$((matched + 1))
    else
      failed=$((failed + 1))
      {
        echo "=== $case_key[$idx] — $unit_path"
        echo "--- ours (a prefix of the check, sorted)"
        head -20 "$WORK/ours.txt"
        echo "--- the reference's C lines"
        head -20 "$WORK/ref.txt"
      } >> "$WORK/failures.txt"
    fi
  done < "$manifest"
done

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
green "DIAGCHECK: OK"
