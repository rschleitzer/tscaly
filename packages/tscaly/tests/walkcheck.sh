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

WORK=$OUT/walkcheck
rm -rf "$WORK"
mkdir -p "$WORK"

units=0
matched=0
failed=0
skipped=0
other=0
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
  # index<TAB>path<TAB>display-name
  while IFS=$'\t' read -r idx unit_path unit_name; do
    [ -n "${idx:-}" ] || continue
    # ★ THE SAME SUFFIX FILTER compare.py's classify_unit applies, and asked of the
    # same field: a corpus case may hold a unit that is not a TypeScript source at
    # all (`/a.tsbuildinfo`), the yardstick does not compare it, and neither may
    # this. Found by the instrument's first run — it reported ONE differing unit
    # over 1 038 and the difference was the missing filter, i.e. the harness rather
    # than the walk. Counted as not-compared rather than skipped in silence.
    case $(printf '%s' "$unit_name" | tr 'A-Z' 'a-z') in
      *.ts|*.mts|*.cts|*.tsx|*.jsx|*.js|*.cjs|*.mjs|*.json) ;;
      *) other=$((other + 1)); continue ;;
    esac
    ref="$case_dir/$idx/types.ref"
    # A unit the ORACLE could not answer (it exits 3, see accepted.txt) has no
    # node list to compare against. Counted, never skipped silently.
    if [ ! -s "$ref" ] && [ -s "$case_dir/$idx/types.ref.err" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    [ -f "$unit_path" ] || { skipped=$((skipped + 1)); continue; }
    units=$((units + 1))
    awk '$1=="T"{print "W", $2, $3, $4}' "$ref" > "$WORK/ref.txt"
    "$BIN" --walk "$unit_path" > "$WORK/ours.txt" 2> "$WORK/ours.err"
    rc=$?
    if [ "$rc" != 0 ]; then
      failed=$((failed + 1))
      {
        echo "=== $case_key[$idx] — our walk exited $rc"
        head -5 "$WORK/ours.err"
      } >> "$WORK/failures.txt"
      continue
    fi
    if cmp -s "$WORK/ours.txt" "$WORK/ref.txt"; then
      matched=$((matched + 1))
    else
      failed=$((failed + 1))
      {
        echo "=== $case_key[$idx] — $unit_path"
        diff "$WORK/ref.txt" "$WORK/ours.txt" | head -20
      } >> "$WORK/failures.txt"
    fi
  done < "$manifest"
done

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
green "WALKCHECK: OK"
