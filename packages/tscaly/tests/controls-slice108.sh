#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice108.sh — the slice-108 battery: THE CALL'S RESOLUTION.
#
# ★★★ THE CHAPTER. `is-untyped-function-call 214` was the largest row slice 107
# could name that is neither the lib nor a name resolution — 52 events over 33 units
# at stage 1, 1 322 units and 4 881 events at stage 2 — and what stood there was one
# `record_unported`. Ported: isUntypedFunctionCall, resolveUntypedCall,
# resolveErrorCall, invocationError/invocationErrorDetails, the four codes TS2347,
# TS2348, TS2349 and TS2351, resolveCall down to chooseOverload's single
# non-generic arm, hasCorrectArity with getMinArgumentCount and getTypeAtPosition
# under it, isSignatureApplicable, checkExpressionWithContextualType, and the three
# singleton signatures slice 89 left named at their readers.
#
# ★★★ THE ROW WAS NOT THE CHAPTER AND A PROBE SAID SO BEFORE A LINE WAS WRITTEN.
# Replacing the stop's tag argument by `ncall*1000 + single_non_generic*100 +
# nargs*10 + ntypeargs` reports 50 of the 52 arrivals as ONE call signature that is
# not generic — every one of them passing every disjunct of the predicate the row is
# named after — and only TWO as untyped calls. So the wall was the OVERLOAD
# RESOLUTION, and the slice is bounded by `s.isSingleNonGenericCandidate` rather
# than by the row.
#
# ★★★ ITS PRODUCT IS A SIGNATURE, AND NO GATE IN THIS PACKAGE COULD SEE ONE. At
# stage 1 the chapter adds THREE diagnostics, all of them on fixtures written for
# it, and the corpus's own calls resolve in silence — so diagcheck moves by the
# fixtures alone, the checker yardstick cannot carry a call's type until
# getTypeOfNode's expression arm lands, and the stop log only says where the walk
# went NEXT. The CALLPIN (`--calls`) is this slice's answer to that, and half the
# rows below are graded on it.
#
# ★★ THE HEAD MESSAGE IS NOT THREADED THROUGH THE RELATION, and one row proves the
# reason rather than asserting it: `chooseOverload` passes reportErrors FALSE, so the
# relation is asked with no error node and selects no message at all.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice108.sh 2>&1 | tee /tmp/battery108.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice108.sh g05 g08` runs the baseline and
# then only the named rows. ★The baseline is NEVER skipped: every verdict below is a
# comparison against it.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
AST=$PKG/0.1.0/tscaly/ast.scaly
FIX=$PKG/tests/fixtures
CASES=$PKG/tests/out/cases

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule) — thirteen of this slice's own. Three
# of them are written for arms with NO INPUT and say so in their own headers
# (callres_rest_parameter, callres_error_target, callres_new_no_arguments); they are
# pinned anyway, because a fixture that gates nothing is invisible until a control
# aims at it (§3.5ap), and controls below aim at all three.
PINFILES="
$FIX/callres_arity_ok.ts
$FIX/callres_arity_wrong.ts
$FIX/callres_untyped.ts
$FIX/callres_untyped_arguments.ts
$FIX/callres_not_callable.ts
$FIX/callres_not_constructable.ts
$FIX/callres_error_target.ts
$FIX/callres_new_no_arguments.ts
$FIX/callres_argument_relation.ts
$FIX/callres_generic_candidate.ts
$FIX/callres_type_arguments.ts
$FIX/callres_rest_parameter.ts
$FIX/callres_spread_argument.ts
"
# ★★★ EVERY DUMPER CALL BELOW RUNS UNDER A TIME LIMIT, for slice 95's reason:
# breaking one bit of a printer can remove the BASE CASE of its own recursion, and
# a process that grows until the machine does is a verdict a battery cannot produce
# without one. `perl -e 'alarm N; exec @ARGV'` is on every box this repo builds on
# and kills at N seconds with rc 142; timeout(1) is not on macOS.
#
# ★★ THE LIMIT IS PART OF THE MEASUREMENT: a killed call writes nothing, so the pin
# and the gate both MOVE, which is the honest verdict for a patch that makes the
# port not terminate.
LIMIT=${LIMIT:-3}
run_limited() { perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$@"; }

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl108)

PATCHED_FILES=""
cleanup() {
  local f i=0
  for f in $PATCHED_FILES; do
    [ -f "$WORK/orig.$i" ] && cp "$WORK/orig.$i" "$f"
    i=$((i+1))
  done
  [ -n "$PATCHED_FILES" ] && red "INTERRUPTED — $PATCHED_FILES restored from the row that was running."
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

build_bins() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE RELPIN — slice 101's instrument; the argument is in RelEvent's own
# header. `A <pos> <source flags> <target flags> <verdict>` per call of
# checkTypeRelatedToAndOptionallyElaborate, verdict 1 RELATED, 0 NOT RELATED, 2
# COULD NOT ANSWER. It exists because this chapter's commonest product is an
# ABSENCE: a relation that answers TRUE writes no diagnostic, no type and — now
# that the stop it replaced is gone — nothing in the stop log either.
relpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --relations "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE KINDPIN — slice 102's instrument; the argument is in KindEvent's own
# header. `K <source flags> <kind> <strict> <arm> <verdict>` per call of
# isTypeAssignableToKindEx. It exists because the RELPIN cannot see this chapter:
# that pin sits at checkTypeRelatedToAndOptionallyElaborate and these calls enter
# the relation one level below it, and most of them never enter it at all.
kindpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --kinds "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE FORKPIN — slice 103's instrument; the argument is in ForkEvent's own
# header. `F <source flags> <target flags> <route> <branch> <verdict>` per call of
# the structured branch of isRelatedToEx. It is asked here for slice 99's reason —
# a new chapter does not replace the old instruments — and it is not idle: an alias
# that answers hands the relation a type where it used to get nothing.
forkpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --forks "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★ THE THREE PINS OF THE LAST TWO SLICES, asked beside this slice's own for
# slice 99's reason — **a new instrument does not replace the old ones**. They are
# asked over the FIXTURES only: a relation change that moved a member table or an
# object-literal type would be a defect of a different kind, and the fixtures are
# where it would show first.
fnpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --functions "$f" 2>/dev/null | tr '\n' '|')"
  done
}

objpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --objlits "$f" 2>/dev/null | tr '\n' '|')"
  done
}

mempin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --members "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE CALLPIN — slice 108's instrument; the argument is in CallEvent's own
# header. `L <pos> <kind> <verdict> <argcount> <paramcount> <minargs>` per call of
# resolve_signature's two ported doors. It exists because this chapter's product is a
# SIGNATURE: a call that resolves writes no diagnostic, no type this port can print,
# and — now that the row is gone — nothing in the stop log either.
callpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --calls "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS RELGATE, beside the pin for slice 92's h08/h11/h25 reason:
# a fixture is written around the arm its author is thinking of, and the shape
# that distinguishes an arm is usually not that shape.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a site that stops being wired moves the ROW count; an arm that answers
# differently moves RELATED against NOT-RELATED; a guard that turns a report into
# a row moves COULD-NOT-ANSWER; and a wrong position or a wrong pair of flag words
# moves only the CHECKSUM.
#
# ★★★ THE PAIR LIST IS NUL-DELIMITED AND THAT IS NOT A STYLE CHOICE — IT IS THE
# DEFECT THIS SLICE FOUND IN ITS OWN HARNESS AND IN THE ONE IT WAS COPIED FROM.
# `xargs` splits on WHITESPACE, the stage-2 corpus holds exactly ONE unit whose
# name contains a space (`u00_①Ⅻㄨㄩ 啊阿…`), and from that unit onward the `-n 2`
# pairing shifts by one — so `> "$2"` redirects the dumper's stdout INTO A CORPUS
# FILE and half the tree is replaced by `cannot read …/rout/009997`. It is
# invisible at stage 1, where no unit path has a space, which is why the pattern
# survived several slices. See §3.5eu finding nine.
relgate() {
  local i=0 u
  rm -rf "$WORK/rout" "$WORK/rpairs"; mkdir -p "$WORK/rout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/rout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/rpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --relations "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/rpairs"
  find "$WORK/rout" -type f -print0 | xargs -0 cat > "$WORK/rel.all"
  local n rel no cna
  n=$(grep -c '^A ' "$WORK/rel.all")
  rel=$(grep '^A ' "$WORK/rel.all" | awk '$5==1' | wc -l | tr -d ' ')
  no=$(grep '^A ' "$WORK/rel.all" | awk '$5==0' | wc -l | tr -d ' ')
  cna=$(grep '^A ' "$WORK/rel.all" | awk '$5==2' | wc -l | tr -d ' ')
  echo "$n $rel $no $cna $(cksum < "$WORK/rel.all" | cut -d' ' -f1)"
}

# ★★★ THE WHOLE-CORPUS KINDGATE, beside the pin for the reason the relgate has one:
# a fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a call site that stops being wired moves the ROW count; an arm that answers
# differently moves TRUE against FALSE; a comparison that starts stopping moves
# COULD-NOT-ANSWER; and a wrong arm number or a wrong flag word moves only the
# CHECKSUM. ★★★The pair list is NUL-delimited and the concatenation goes through
# `find | xargs cat` for §3.5eu finding nine's two reasons: one stage-2 unit's path
# contains a SPACE, which shifts an `xargs -n 2` pairing and redirects the dumper's
# stdout into a CORPUS FILE, and `cat "$WORK"/kout/*` is *Argument list too long* at
# 17 552 files — a gate that cannot RUN and a gate that cannot FAIL print the same
# word.
kindgate() {
  local i=0 u
  rm -rf "$WORK/kout" "$WORK/kpairs"; mkdir -p "$WORK/kout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/kout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/kpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --kinds "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/kpairs"
  find "$WORK/kout" -type f -print0 | xargs -0 cat > "$WORK/kind.all"
  local n t f cna
  n=$(grep -c '^K ' "$WORK/kind.all")
  t=$(grep '^K ' "$WORK/kind.all" | awk '$6==1' | wc -l | tr -d ' ')
  f=$(grep '^K ' "$WORK/kind.all" | awk '$6==0' | wc -l | tr -d ' ')
  cna=$(grep '^K ' "$WORK/kind.all" | awk '$6==2' | wc -l | tr -d ' ')
  echo "$n $t $f $cna $(cksum < "$WORK/kind.all" | cut -d' ' -f1)"
}

# ★★★ THE WHOLE-CORPUS FORKGATE, beside the pin for the relgate's reason: a
# fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape.
#
# ★★ IT IS FOUR NUMBERS AND A CHECKSUM plus TWO HISTOGRAMS, and the histograms are
# what no other gate in this family has. Four breakages are told apart without a
# diff: a site that stops being wired moves the ROW count; an arm that answers
# differently moves TRUE against FALSE; a guard that turns an answer into a stop
# moves COULD-NOT-ANSWER; and a wrong flag word moves only the CHECKSUM. ★★★The
# ROUTE histogram is the one that prices the successor — route 3 is what is left
# for the recursion — and the BRANCH histogram is the one that separates a broken
# arm from an arm with no input, which is the KINDPIN's argument arriving in a
# second chapter.
#
# ★ NUL-delimited and concatenated through `find | xargs cat`, for §3.5eu finding
# nine's two reasons: one stage-2 unit's path contains a SPACE, which shifts an
# `xargs -n 2` pairing and redirects the dumper's stdout into a CORPUS FILE, and
# `cat "$WORK"/fout/*` is *Argument list too long* at 17 552 files.
forkgate() {
  local i=0 u
  rm -rf "$WORK/fout" "$WORK/fpairs"; mkdir -p "$WORK/fout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/fout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/fpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --forks "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/fpairs"
  find "$WORK/fout" -type f -print0 | xargs -0 cat > "$WORK/fork.all"
  local n t f cna routes branches
  n=$(grep -c '^F ' "$WORK/fork.all")
  t=$(grep '^F ' "$WORK/fork.all" | awk '$6==1' | wc -l | tr -d ' ')
  f=$(grep '^F ' "$WORK/fork.all" | awk '$6==0' | wc -l | tr -d ' ')
  cna=$(grep '^F ' "$WORK/fork.all" | awk '$6==2' | wc -l | tr -d ' ')
  routes=$(grep '^F ' "$WORK/fork.all" | awk '{print $4}' | sort | uniq -c | awk '{printf "%s:%s ", $2, $1}')
  branches=$(grep '^F ' "$WORK/fork.all" | awk '$4==2{print $5}' | sort -n | uniq -c | awk '{printf "%s:%s ", $2, $1}')
  echo "$n $t $f $cna $(cksum < "$WORK/fork.all" | cut -d' ' -f1) | routes ${routes}| branches ${branches}"
}

# ★★★ THE WHOLE-CORPUS CALLGATE, beside the pin for the relgate's reason: a fixture
# is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape.
#
# ★★ IT IS FIVE NUMBERS AND A CHECKSUM, so four breakages are told apart without a
# diff: a call site that stops being wired moves the ROW count; an arm that answers
# differently moves RESOLVED against COULD-NOT-ANSWER; a singleton returned where a
# candidate belongs moves UNTYPED or ERROR; and a wrong arity column moves only the
# CHECKSUM. ★NUL-delimited and concatenated through `find | xargs cat`, for §3.5eu
# finding nine's two reasons.
callgate() {
  local i=0 u
  rm -rf "$WORK/lout" "$WORK/lpairs"; mkdir -p "$WORK/lout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/lout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/lpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --calls "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/lpairs"
  find "$WORK/lout" -type f -print0 | xargs -0 cat > "$WORK/call.all"
  local n res cna unt err
  n=$(grep -c '^L ' "$WORK/call.all")
  cna=$(grep '^L ' "$WORK/call.all" | awk '$4==0' | wc -l | tr -d ' ')
  res=$(grep '^L ' "$WORK/call.all" | awk '$4==1' | wc -l | tr -d ' ')
  unt=$(grep '^L ' "$WORK/call.all" | awk '$4==2' | wc -l | tr -d ' ')
  err=$(grep '^L ' "$WORK/call.all" | awk '$4==3' | wc -l | tr -d ' ')
  echo "$n $res $unt $err $cna $(cksum < "$WORK/call.all" | cut -d' ' -f1)"
}

stopgate() {   # writes "matched units speaking events other" to stdout
  BIN=$WORK/tscaly_types packages/tscaly/tests/stops.sh > "$WORK/stops.out" 2>&1
  local m u s e o
  m=$(sed -n 's/^  agreeing with the work list  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  u=$(sed -n 's/^  units compared  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  s=$(sed -n 's/^  units with a stop  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  e=$(sed -n 's/^  stop events  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  o=$(sed -n 's/^  parse\/bind stop  *\([0-9]*\).*$/\1/p' "$WORK/stops.out")
  echo "$m $u $s $e $o"
}

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; REL_BASE=""; KIND_BASE=""; FORK_BASE=""; CALL_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — thirteen instruments"
  if ! build_bins; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  diags_of > "$WORK/base.diags"
  stops_of > "$WORK/base.stops"
  relpin_of > "$WORK/base.rel"
  kindpin_of > "$WORK/base.kind"
  forkpin_of > "$WORK/base.fork"
  fnpin_of > "$WORK/base.fn"
  objpin_of > "$WORK/base.obj"
  mempin_of > "$WORK/base.mem"
  callpin_of > "$WORK/base.call"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.mts' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  REL_BASE=$(relgate)
  KIND_BASE=$(kindgate)
  FORK_BASE=$(forkgate)
  CALL_BASE=$(callgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the RELPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.rel"
  echo
  echo "  the KINDPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.kind"
  echo
  echo "  the FORKPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.fork"
  echo
  echo "  the CALLPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.call"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             relgate   (rows related notrelated couldnotanswer checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $REL_BASE"
  echo "             kindgate  (rows true false couldnotanswer checksum) over the same units = $KIND_BASE"
  echo "             forkgate  (rows true false couldnotanswer checksum | routes | branches) = $FORK_BASE"
  echo "             callgate  (rows resolved untyped errorcall couldnotanswer checksum) = $CALL_BASE"
}

ONLY="$*"

control() {   # $1 = label, $2 = files, $3 = patch
  if [ -n "$ONLY" ]; then
    case " $ONLY " in
      *" ${1%% *} "*) ;;
      *) return 0 ;;
    esac
  fi
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_FILES="$files"
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  echo "  patched $files"
  if ! build_bins; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags stop
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  diags_of > "$WORK/ctl.diags"
  stops_of > "$WORK/ctl.stops"
  relpin_of > "$WORK/ctl.rel"
  kindpin_of > "$WORK/ctl.kind"
  forkpin_of > "$WORK/ctl.fork"
  fnpin_of > "$WORK/ctl.fn"
  objpin_of > "$WORK/ctl.obj"
  mempin_of > "$WORK/ctl.mem"
  callpin_of > "$WORK/ctl.call"
  stop=$(stopgate)
  local rel_g kind_g fork_g call_g
  rel_g=$(relgate)
  kind_g=$(kindgate)
  fork_g=$(forkgate)
  call_g=$(callgate)
  local restored=1
  i=0
  for f in $files; do
    cp "$WORK/orig.$i" "$f"
    cmp -s "$WORK/orig.$i" "$f" || restored=0
    i=$((i+1))
  done
  if [ "$restored" != 1 ]; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILES=""
  echo "  RESTORE VERIFIED   $files byte-identical"
  echo
  local moved=0
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
    moved=1
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.diags" "$WORK/ctl.diags"; then
    echo "  diagpin   unmoved — all thirteen pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all thirteen pin files answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all thirteen pin files log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.rel" "$WORK/ctl.rel"; then
    echo "  relpin    unmoved — all thirteen pin files make the same comparisons, in order."
  else
    green "relpin    RED"
    diff "$WORK/base.rel" "$WORK/ctl.rel" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.kind" "$WORK/ctl.kind"; then
    echo "  kindpin   unmoved — all thirteen pin files ask the same kinds and take the same arms."
  else
    green "kindpin   RED"
    diff "$WORK/base.kind" "$WORK/ctl.kind" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.fn" "$WORK/ctl.fn"; then
    echo "  fnpin     unmoved — all thirteen pin files decide the same way, in the same order."
  else
    green "fnpin     RED"
    diff "$WORK/base.fn" "$WORK/ctl.fn" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.obj" "$WORK/ctl.obj"; then
    echo "  objpin    unmoved — all thirteen pin files build the same object-literal types."
  else
    green "objpin    RED"
    diff "$WORK/base.obj" "$WORK/ctl.obj" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if cmp -s "$WORK/base.mem" "$WORK/ctl.mem"; then
    echo "  mempin    unmoved — all thirteen pin files resolve the same members."
  else
    green "mempin    RED"
    diff "$WORK/base.mem" "$WORK/ctl.mem" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$rel_g" = "$REL_BASE" ]; then
    echo "  relgate   unmoved — $rel_g"
  else
    green "relgate   MOVED   $REL_BASE -> $rel_g   (rows related notrelated couldnotanswer checksum)"
    moved=1
  fi
  if [ "$kind_g" = "$KIND_BASE" ]; then
    echo "  kindgate  unmoved — $kind_g"
  else
    green "kindgate  MOVED   $KIND_BASE -> $kind_g   (rows true false couldnotanswer checksum)"
    moved=1
  fi
  if cmp -s "$WORK/base.fork" "$WORK/ctl.fork"; then
    echo "  forkpin   unmoved — all thirteen pin files take the same routes and answer the same."
  else
    green "forkpin   RED"
    diff "$WORK/base.fork" "$WORK/ctl.fork" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$fork_g" = "$FORK_BASE" ]; then
    echo "  forkgate  unmoved — $fork_g"
  else
    green "forkgate  MOVED"
    echo "    was $FORK_BASE"
    echo "    now $fork_g"
    moved=1
  fi
  if cmp -s "$WORK/base.call" "$WORK/ctl.call"; then
    echo "  callpin   unmoved — all thirteen pin files resolve the same calls, in order."
  else
    green "callpin   RED"
    diff "$WORK/base.call" "$WORK/ctl.call" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$call_g" = "$CALL_BASE" ]; then
    echo "  callgate  unmoved — $call_g"
  else
    green "callgate  MOVED   $CALL_BASE -> $call_g   (rows resolved untyped errorcall couldnotanswer checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all fourteen, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL FOURTEEN AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}




PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)
P = {}

P['g01'] = ('''# THE PREMISE — resolveCallExpression's tail reverted to the single
# `record_unported` it carried through slice 107. PREDICTION: the callgate loses
# every resolution and every singleton, the stopgate grows back the 52 events the row
# used to carry, the diagpin loses the three diagnostics the fixtures produce, and
# diagcheck stays GREEN WITH A NUMBER because a LOSS is a legal subsequence. It is
# the row every other row is read against.''',
"""old = '''        let num_call Checker.sig_count(call_sigs)'''
new = '''        this.record_unported("is-untyped-function-call", KindCallExpression)
        if true
            return null
        let num_call Checker.sig_count(call_sigs)'''""")

P['g02'] = ('''# THE FIRST DISJUNCT — `IsTypeAny(funcType)` — dropped. PREDICTION: the two untyped
# fixtures lose their verdict 2 and callres_untyped loses its TS2347, so the callpin
# is RED and diagcheck stays green at a LOSS. ★★It is the ONLY one of the four
# disjuncts with input at stage 1, which a probe measured before the chapter was
# written: 2 of the 52 arrivals.''',
"""old = '''        if Checker.is_type_any(func_type)
            return true
        if Checker.is_type_any(apparent_func_type)'''
new = '''        if false
            return true
        if Checker.is_type_any(apparent_func_type)'''""")

P['g03'] = ('''# isUntypedFunctionCall FORCED TRUE — every call becomes an untyped call.
# PREDICTION: the callgate's RESOLVED column collapses into UNTYPED and diagcheck
# goes RED by INVENTION, because every call that carries type arguments then reports
# TS2347. It is the LOUD port of this predicate; g02 is the silent one.''',
"""old = '''        if Checker.is_type_any(func_type)
            return true
        if Checker.is_type_any(apparent_func_type)'''
new = '''        if true
            return true
        if Checker.is_type_any(apparent_func_type)'''""")

P['g04'] = ('''# THE THIRD DISJUNCT'S FIRST CONJUNCT dropped, so the `globalFunctionType` term is
# reached whenever the other three hold. PREDICTION: callres_not_callable's TS2348
# goes and its call stops at `global-function-type` instead, which is the row's
# SECOND call site becoming live — and the stopgate says so. ★★★It is the row that
# proves the containment argument in isUntypedFunctionCall's header: the corpus fails
# THIS conjunct, not the lib term, and that is why the lib term reads zero.''',
"""old = '''        if num_call_signatures <> 0
            return false
        if num_construct_signatures <> 0
            return false'''
new = '''        if num_construct_signatures <> 0
            return false'''""")

P['g05'] = ('''# THE UNION EXCLUSION dropped — the reference's own comment being *we exclude union
# types because we may have a union of function types that happen to have no common
# signatures*. PREDICTION: UNGATED. Every arrival that gets past the two signature
# counts stops at the lib term anyway, so removing a test in front of a wall cannot
# change an answer; what it WOULD change is which row the arrival lands in, and
# get_reduced_type's union arm is a row too.''',
"""old = '''        if (apparent_func_type.flags & TypeFlagsUnion) <> 0
            return false
        let mark this.unported_mark()
        let reduced this.get_reduced_type(apparent_func_type)'''
new = '''        let mark this.unported_mark()
        let reduced this.get_reduced_type(apparent_func_type)'''""")

P['g06'] = ('''# THE SECOND DISJUNCT — an apparent type of `any` over a funcType that is a TYPE
# PARAMETER — dropped. PREDICTION: UNGATED. It needs a type parameter whose
# constraint resolves to `any`, and get_apparent_type's Instantiable arm answers
# `unknown` for an unconstrained one; no fixture and no corpus unit has the shape.''',
"""old = '''        if Checker.is_type_any(apparent_func_type)
        {
            if (func_type.flags & TypeFlagsTypeParameter) <> 0
                return true
        }'''
new = '''        if false
        {
            if (func_type.flags & TypeFlagsTypeParameter) <> 0
                return true
        }'''""")

P['g07'] = ('''# TS2347 reported on EVERY untyped call, not only on one carrying type arguments.
# PREDICTION: diagcheck RED by INVENTION — callres_untyped_arguments has an untyped
# call with no type arguments and the reference is silent about it. ★It is the
# direction a subsequence CAN see, which is why the guard gets a row and its
# unreachable sibling below gets an argument instead.''',
"""old = '''                if AstNode.type_arguments_of(node) <> null
                    this.error_on_node(node, DiagUntyped_function_calls_may_not_accept_type_arguments)'''
new = '''                this.error_on_node(node, DiagUntyped_function_calls_may_not_accept_type_arguments)'''""")

P['g08'] = ('''# THE ERROR-TYPE GUARD in front of TS2347 dropped. PREDICTION: UNGATED, and the
# argument is at its line: getApparentType of errorType IS errorType, so
# `is_error_type(at)` two arms above has already returned for every funcType this
# guard could catch. The reference asks it of funcType and not of the apparent type,
# and only that asymmetry keeps the line alive at all.''',
"""old = '''            if this.is_error_type(fnt) = false
            {
                if AstNode.type_arguments_of(node) <> null'''
new = '''            if true
            {
                if AstNode.type_arguments_of(node) <> null'''""")

P['g09'] = ('''# THE TS2348 ARM — `Value of type is not callable. Did you mean to include new?` —
# dropped, so a construct-only type falls into invocationError instead.
# PREDICTION: diagpin RED on callres_not_callable, and diagcheck GREEN because the
# code CHANGES rather than disappearing: the fallthrough reports TS2349 at the same
# span, which is a substitution and not a subsequence violation. ★★That is exactly
# the shape §3.5's rule about diagcheck warns of, and the diagpin is the partner
# that sees it.''',
"""old = '''            if num_construct <> 0
            {
                this.error_on_node(node, DiagValue_of_type_0_is_not_callable_Did_you_mean_to_include_new)
                return this.resolve_error_call(node)
            }'''
new = '''            if false
            {
                this.error_on_node(node, DiagValue_of_type_0_is_not_callable_Did_you_mean_to_include_new)
                return this.resolve_error_call(node)
            }'''""")

P['g10'] = ('''# THE HEAD MESSAGE forced to `This_expression_is_not_callable` for both signature
# kinds. PREDICTION: diagcheck RED by INVENTION on callres_not_constructable and
# callres_error_target — the reference reports TS2351 there and this reports TS2349,
# and an unexpected code at an expected span is exactly what a subsequence catches.''',
"""old = '''        var head DiagThis_expression_is_not_callable
        if kind <> SignatureKindCall
            set head: DiagThis_expression_is_not_constructable'''
new = '''        var head DiagThis_expression_is_not_callable
        if false
            set head: DiagThis_expression_is_not_constructable'''""")

P['g11'] = ('''# THE RETARGET — `target = errorTarget.Name()` when the callee is a property access
# under a CALL — dropped. PREDICTION: UNGATED, with the covering wall named:
# invocationError is unreachable from the CALL side (isUntypedFunctionCall's third
# disjunct stops at `global-function-type` for exactly the population TS2349 is
# about), and from the `new` side the parent is a NewExpression, so the condition is
# false by construction. callres_error_target pins the span the port DOES produce.''',
"""old = '''            if parent_is_call
            {
                let nm AstNode.name_of(error_target)
                if nm <> null
                    set target: nm as ref[AstNode]
            }'''
new = '''            if false
            {
                let nm AstNode.name_of(error_target)
                if nm <> null
                    set target: nm as ref[AstNode]
            }'''""")

P['g12'] = ('''# THE GET-ACCESSOR HEAD — TS6234, `This expression is not callable because it is a
# get accessor` — dropped. PREDICTION: UNGATED, unreachable behind
# `get-type-of-accessors`: a getter's TYPE cannot be computed here, so the call never
# reaches invocationError. It is written because the arm is the ONE thing that can
# move invocationErrorDetails' head, and a chapter that leaves its only variable
# unwritten has not been read.''',
"""old = '''                    if (Symbol.flags_of(rs as ref[Symbol]) & SymbolFlagsGetAccessor) <> 0
                        set head: DiagThis_expression_is_not_callable_because_it_is_a_get_accessor_Did_you_mean_to_use_it_without'''
new = '''                    if false
                        set head: DiagThis_expression_is_not_callable_because_it_is_a_get_accessor_Did_you_mean_to_use_it_without'''""")

P['g13'] = ('''# THE ARGUMENT WALK of resolveUntypedCall dropped. PREDICTION: diagpin RED on
# callres_untyped_arguments at a LOSS — its argument is a PRIVATE property access, so
# the TS2341 the walk produces is the only observable consequence the walk has, and
# without it the file goes silent while the call still answers `any_signature`.
# ★★The reference's own comment is what the row prices: the arguments are checked
# *even though we will give an error*, so the report and the walk are not
# alternatives.''',
"""old = '''            if arg <> null
            {
                let ignored this.check_expression(arg as ref[AstNode])
                if this.unported_mark() <> mark
                    return null
            }'''
new = '''            if false
            {
                let ignored this.check_expression(arg as ref[AstNode])
                if this.unported_mark() <> mark
                    return null
            }'''""")

P['g14'] = ('''# `checkSourceElements(node.TypeArguments())` inside resolveUntypedCall dropped.
# PREDICTION: UNGATED with a number, or ungated outright — callres_untyped's type
# argument is `number`, a keyword type node that produces no diagnostic, and no
# fixture puts a reporting type argument on an untyped call. ★It is the second half
# of the reference's comment and it is priced separately from g13 because the two
# walks are over different lists.''',
"""old = '''        if Checker.call_like_expression_may_have_type_arguments(node)
            this.check_source_elements(AstNode.type_arguments_of(node))'''
new = '''        if false
            this.check_source_elements(AstNode.type_arguments_of(node))'''""")

P['g15'] = ('''# THE `n_sigs > 1` ROW REMOVED, so an overloaded callee is resolved against its
# FIRST signature. PREDICTION: the callgate's RESOLVED and COULD-NOT-ANSWER columns
# both move, and diagcheck may go RED by INVENTION where the first overload rejects
# an argument the second accepts. ★★★It is the row that says why the boundary is
# where it is: reorderCandidates plus the two-pass chooseOverload is not a detail
# that can be skipped, it decides WHICH signature answers.''',
"""old = '''            this.record_unported("reorder-candidates", n_sigs)
            return null'''
new = '''            let ignored_reorder n_sigs'''""")

P['g16'] = ('''# `len(candidates) == 0` answering null instead of `unknownSignature`. PREDICTION:
# UNGATED — resolveCall is reached from resolveCallExpression only when
# `num_call <> 0`, so the branch has no input at all; the reference keeps it for a
# reason it states itself (*in Strada we would error here, but no known repro
# doesn't have at least one other error in this codepath*).''',
"""old = '''            ; "In Strada we would error here, but no known repro doesn't have at
            ; least one other error in this codepath. Just return instead."
            return unknown_signature'''
new = '''            return null'''""")

P['g17'] = ('''# `checkSourceElements(s.typeArguments)` inside resolveCall dropped. PREDICTION:
# diagpin RED at a LOSS on callres_type_arguments or ungated with a number — the walk
# is what gives a call's type arguments their own diagnostics, and this slice's only
# fixture with type arguments on a non-generic candidate writes `number`.''',
"""old = '''        if Checker.kind_or_unknown(AstNode.expression_of(node)) <> KindSuperKeyword
            this.check_source_elements(type_arguments)'''
new = '''        if false
            this.check_source_elements(type_arguments)'''""")

P['g18'] = ('''# `single_non_generic` inverted — a generic candidate is treated as non-generic and
# a non-generic one goes to the inference row. PREDICTION: the callgate moves in BOTH
# columns and the callpin is RED on nearly every pin file. ★★It is the row that says
# the test is a FORK and not a guard: neither direction is a subset of the other.''',
"""old = '''        if single_non_generic = false
        {'''
new = '''        if single_non_generic
        {'''""")

P['g19'] = ('''# `if len(s.typeArguments) != 0 … return nil` dropped, so a NON-generic candidate
# handed type arguments is resolved anyway. PREDICTION: callres_type_arguments'
# call resolves — the callpin is RED and the callgate's RESOLVED column grows — while
# the reference reports TS2558 there. ★★It is an INVENTION the callgate can see and
# diagcheck cannot, because what this port invents is a resolution and not a
# diagnostic.''',
"""old = '''            this.record_unported("get-candidate-for-overload-failure-type-arguments", KindCallExpression)
            return null'''
new = '''            let ignored_ta 0'''""")

P['g20'] = ('''# THE UPPER BOUND — `!hasEffectiveRestParameter && argCount > effectiveParameterCount`
# — dropped. PREDICTION: `f(1, 2, 3)` in callres_arity_wrong resolves against a
# two-parameter signature, so the callpin is RED and the callgate's RESOLVED column
# grows by one; the reference reports TS2554 on that line. ★It is one of the two
# directions of the arity test and its partner is g21.''',
"""old = '''        if rest = false
        {
            if arg_count > effective_parameter_count
                return false
        }'''
new = '''        if rest = false
        {
            if false
                return false
        }'''""")

P['g21'] = ('''# THE LOWER BOUND — `argCount >= effectiveMinimumArguments` made unconditional —
# dropped. PREDICTION: `f(1)` against a two-parameter signature and `g(1)` against a
# zero-parameter one both resolve, so the callpin is RED on callres_arity_wrong.
# g20's opposite direction, and both are needed because the two tests read different
# accessors: one the parameter COUNT, the other the MINIMUM.''',
"""old = '''        if arg_count >= effective_minimum_arguments
            return true'''
new = '''        if true
            return true'''""")

P['g22'] = ('''# `callIsIncomplete` forced FALSE, so the lower-bound skip for an unterminated call
# never fires. PREDICTION: UNGATED. It is TRUE only when the closing parenthesis is
# MISSING — `node.ArgumentList().End() == node.End()` — and every fixture and every
# corpus unit that reaches the arity check is well-formed there. ★★The line is not
# cosmetic even so: it is the only reader of the argument list's RANGE, and g27 is
# the row that prices the range lookup itself.''',
"""old = '''        if lend = AstNode.end_of(node)
            set call_is_incomplete: true'''
new = '''        if false
            set call_is_incomplete: true'''""")

P['g23'] = ('''# THE VOID LOOP of getMinArgumentCountEx dropped — the walk that lowers the minimum
# past every trailing parameter whose type accepts `void`. PREDICTION: UNGATED, and
# the reason is which accessor sets the number: an OPTIONAL parameter already carries
# `min_argument_count` from the binder, so the loop only matters for a parameter
# DECLARED `void`, which no fixture and no corpus unit that reaches here has.''',
"""old = '''            if Checker.some_type_accepts_void(t as ref[Type]) = false
                break
            set min_argument_count: i'''
new = '''            if true
                break
            set min_argument_count: i'''""")

P['g24'] = ('''# getMinArgumentCount forced to 0. PREDICTION: the callpin is RED on
# callres_arity_wrong — `f(1)` and `g(1)`'s too-few sibling now pass the lower bound
# — and the arity columns of every resolved row on callres_arity_ok move, because the
# pin records the minimum whatever the verdict. ★★★It is the row that says the two
# arity numbers are worth their own columns: g21 removes the TEST and this removes
# the NUMBER, and only the checksum tells them apart.''',
"""old = '''            set min_argument_count: signature.min_argument_count'''
new = '''            set min_argument_count: 0'''""")

P['g25'] = ('''# THE `new C` ARM — `IsNewExpression(node) && node.ArgumentList() == nil` — dropped.
# PREDICTION: UNGATED, unreachable, with the covering stops named: resolveCall is not
# reached from the `new` side at all, a `new` with construct signatures stopping at
# `is-constructor-accessible` and one with only call signatures at
# `resolve-call-of-new-expression`. callres_new_no_arguments is the fixture that
# would see it and it predicts the silence.''',
"""old = '''            if AstNode.call_arguments_of(node) = null
                return effective_minimum_arguments = 0'''
new = '''            if false
                return effective_minimum_arguments = 0'''""")

P['g26'] = ('''# THE SPREAD arm of hasCorrectArity dropped. PREDICTION: UNGATED — a spread argument
# stops one function earlier, in get_effective_call_arguments, so the arm has no
# input. callres_spread_argument is the fixture and its stop log names the covering
# row. ★It is written because the reference's arm answers RETURN rather than falling
# through, so folding it away would change the shape of the function and not only
# its coverage.''',
"""old = '''            let rest_for_spread this.has_effective_rest_parameter(signature)
            if this.unported_mark() <> mark
                return false
            if rest_for_spread
                return true'''
new = '''            let rest_for_spread this.has_effective_rest_parameter(signature)
            if this.unported_mark() <> mark
                return false
            if true
                return true'''""")

P['g27'] = ('''# THE RANGE LOOKUP's stop replaced by *assume the call is complete*. PREDICTION:
# UNGATED, and that is a PROOF rather than a coverage claim: every argument list this
# chapter meets is in the side table, so the stop never fires and the guess never
# differs. ★★★The row exists because the alternative is the shape this file calls a
# well-formed wrong answer — the fifth yardstick compares spans, and a range invented
# here would look exactly like a measured one.''',
"""old = '''            this.record_unported("argument-list-range", k)
            return false'''
new = '''            set call_is_incomplete: false'''""")

P['g28'] = ('''# THE ARGUMENT LOOP of isSignatureApplicable dropped — every candidate with the
# right arity becomes applicable. PREDICTION: callres_argument_relation's two calls
# resolve, so the callpin is RED and the callgate's RESOLVED column grows by two
# while the reference reports TS2345 on both. ★★It is the whole reason the relation
# is in this chapter: without it, arity alone would answer.''',
"""old = '''        var i 0
        while i < arg_count
        {
            let arg AstNode.child_in_list(args, i)
            if arg = null
            {
                this.record_unported("argument-slot-missing", AstNode.kind_of(node))
                return false
            }'''
new = '''        var i arg_count
        while i < arg_count
        {
            let arg AstNode.child_in_list(args, i)
            if arg = null
            {
                this.record_unported("argument-slot-missing", AstNode.kind_of(node))
                return false
            }'''""")

P['g29'] = ('''# THE ELISION SKIP dropped, so an OmittedExpression argument is typed and compared.
# PREDICTION: UNGATED — `f(, 1)` is a parse error and no fixture or corpus unit
# reaching this loop carries one. ★It is the reference's own guard and it is written
# rather than folded because the shape it protects against is a node with no
# expression at all, which would be a member-not-found rather than a wrong answer.''',
"""old = '''            if AstNode.kind_of(a) <> KindOmittedExpression'''
new = '''            if true'''""")

P['g30'] = ('''# `checkExpressionWithContextualType` replaced by a plain `check_expression`, so the
# argument is typed with no expectation. PREDICTION: the callgate's checksum moves at
# least, and the callpin may be RED: the contextual type is what keeps a fresh literal
# from widening, and `f(1)` against `(a: number)` is assignable either way while a
# literal-typed parameter is not. ★★It is also the row that prices the pop: a leaked
# contextual frame is a wrong answer for the NEXT caller, not for this one.''',
"""old = '''                let at0 this.check_expression_with_contextual_type(a, param_type, check_mode)'''
new = '''                let at0 this.check_expression(a)'''""")

P['g31'] = ('''# THE `this`-ARGUMENT ROW forced to fire on every call, by treating the signature's
# `this` type as always present and never void. PREDICTION: the callgate's RESOLVED
# column goes to zero and every pin file's callpin is RED — which is what proves the
# arm is REACHED. Without this row, an arm that stands in front of every argument
# walk and never fires reads exactly like one that is dead.''',
"""old = '''        if this_type <> null
        {
            let tt this_type as ref[Type]
            if tt <> void_type
            {'''
new = '''        if true
        {
            let tt any_type
            if tt <> void_type
            {'''""")

P['g32'] = ('''# THE REST TAIL of isSignatureApplicable dropped — `getSpreadArgumentType` and the
# comparison under it. PREDICTION: UNGATED, unreachable twice over:
# get_non_array_rest_type stops before it can answer non-nil, and the array type node
# a rest parameter needs is itself a row (callres_rest_parameter's own header).''',
"""old = '''            this.record_unported("get-spread-argument-type", AstNode.kind_of(node))
            return false'''
new = '''            let ignored_spread 0'''""")

P['g33'] = ('''# THE UNION ARM of isLiteralOfContextualType reverted to the row it was until this
# slice. PREDICTION: the callpin is RED on callres_arity_ok — `h(1)` and `i(3)` lose
# their resolution — because an OPTIONAL parameter's contextual type is
# `number | undefined`, a union, and the very first thing the argument walk meets is
# that union. ★★★It is the row that says why a two-line arm in a different chapter
# had to land in this slice: without it, every optional parameter in the corpus was
# a wall.''',
"""old = '''        if (ct.flags & TypeFlagsUnion) <> 0
        {
            let types Checker.union_types_of(ct)'''
new = '''        if (ct.flags & TypeFlagsUnion) <> 0
        {
            this.record_unported("is-literal-of-contextual-type-union", 0)
            return false
        }
        if false
        {
            let types Checker.union_types_of(ct)'''""")

P['g34'] = ('''# checkDeprecatedSignature REVERTED to the row slice 89 wrote at
# `sig.declaration != nil`. PREDICTION: the callgate's RESOLVED column collapses and
# the stopgate grows by the 14 events the first corpus run of this slice measured —
# every one of them a call that had just been resolved and then lost its type to a
# SUGGESTION nothing in this package compares. ★★★It is the slice's own finding as a
# row: the deferral's justification — *the second conjunct is the row and the first is
# ported* — had expired in slice 95, six slices before this chapter gave the row its
# first input, and nothing re-read it.''',
"""old = '''        if this.is_deprecated_declaration(sig.declaration as ref[AstNode]) = false
            return
        this.record_unported("add-deprecated-suggestion", AstNode.kind_of(node))'''
new = '''        this.record_unported("is-deprecated-declaration", AstNode.kind_of(node))'''""")

P['g35'] = ('''# THE silentNeverType ARM reverted to the row it carried through slice 107.
# PREDICTION: UNGATED. It read ZERO events in both stages before this slice and the
# singleton is minted anyway, because a stop kept beside a minted sibling is a wall
# that is no longer there — which is a claim this row is the only way to check.''',
"""old = '''        if fnt = silent_never_type
            return silent_never_signature'''
new = '''        if fnt = silent_never_type
        {
            this.record_unported("silent-never-signature", KindCallExpression)
            return null
        }'''""")

P['g36'] = ('''# resolveErrorCall answering null instead of `unknownSignature`. PREDICTION: the
# callpin loses its verdict-3 rows on callres_not_callable, callres_not_constructable,
# callres_error_target and callres_new_no_arguments — four pin files — while the
# DIAGNOSTICS stay, because the report is emitted before the answer. ★★It is the row
# that separates a singleton from a report: a caller that reads nil as *the check
# stopped* is the shape slice 88's finding one is about, and here nothing stopped.''',
"""old = '''    function resolve_error_call(this, node: ref[AstNode]) returns ref[Signature]?
    {
        let mark this.unported_mark()
        let ignored this.resolve_untyped_call(node)
        if this.unported_mark() <> mark
            return null
        unknown_signature
    }'''
new = '''    function resolve_error_call(this, node: ref[AstNode]) returns ref[Signature]?
    {
        let mark this.unported_mark()
        let ignored this.resolve_untyped_call(node)
        if this.unported_mark() <> mark
            return null
        null
    }'''""")

for name, (why, body) in list(P.items()):
    open(os.path.join(D, name + '.py'), 'w').write(
        "import sys\n" + why + "\n" + body +
        "\npath = sys.argv[1]\ns = open(path).read()\n"
        "assert old in s, 'anchor moved: ' + repr(old[:60])\n"
        "assert s.count(old) == 1, 'anchor is not unique: ' + repr(old[:60])\n"
        "s = s.replace(old, new)\n"
        "try:\n    old2\nexcept NameError:\n    pass\nelse:\n"
        "    assert old2 in s, 'anchor 2 moved'\n    assert s.count(old2) == 1, 'anchor 2 is not unique'\n    s = s.replace(old2, new2)\n"
        "open(path, 'w').write(s)\n")
MKPATCHES

baseline

control "g01 THE PREMISE — the chapter back to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 isUntypedFunctionCall's FIRST disjunct dropped" $CHECKER "$PATCHDIR/g02.py"
control "g03 isUntypedFunctionCall forced TRUE" $CHECKER "$PATCHDIR/g03.py"
control "g04 the `num_call <> 0` SHORT CIRCUIT dropped" $CHECKER "$PATCHDIR/g04.py"
control "g05 the UNION EXCLUSION dropped" $CHECKER "$PATCHDIR/g05.py"
control "g06 the SECOND disjunct dropped" $CHECKER "$PATCHDIR/g06.py"
control "g07 TS2347's TYPE-ARGUMENT GUARD dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 the `is_error_type(fnt)` GUARD dropped" $CHECKER "$PATCHDIR/g08.py"
control "g09 the TS2348 arm dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 invocationError's HEAD forced to the CALL code" $CHECKER "$PATCHDIR/g10.py"
control "g11 the PROPERTY-ACCESS RETARGET dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the GET-ACCESSOR HEAD arm dropped" $CHECKER "$PATCHDIR/g12.py"
control "g13 resolveUntypedCall's ARGUMENT WALK dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 resolveUntypedCall's TYPE-ARGUMENT CHECK dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 the MULTI-CANDIDATE row moved BELOW the candidate read" $CHECKER "$PATCHDIR/g15.py"
control "g16 the EMPTY-CANDIDATE answer changed to null" $CHECKER "$PATCHDIR/g16.py"
control "g17 resolveCall's TYPE-ARGUMENT WALK dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 the SINGLE-NON-GENERIC test INVERTED" $CHECKER "$PATCHDIR/g18.py"
control "g19 the TYPE-ARGUMENTS EARLY-OUT of chooseOverload dropped" $CHECKER "$PATCHDIR/g19.py"
control "g20 hasCorrectArity's TOO-MANY test dropped" $CHECKER "$PATCHDIR/g20.py"
control "g21 hasCorrectArity's TOO-FEW test dropped" $CHECKER "$PATCHDIR/g21.py"
control "g22 callIsIncomplete forced FALSE" $CHECKER "$PATCHDIR/g22.py"
control "g23 getMinArgumentCount's VOID LOOP dropped" $CHECKER "$PATCHDIR/g23.py"
control "g24 getMinArgumentCount forced to ZERO" $CHECKER "$PATCHDIR/g24.py"
control "g25 hasCorrectArity's NewExpression arm dropped" $CHECKER "$PATCHDIR/g25.py"
control "g26 hasCorrectArity's SPREAD arm dropped" $CHECKER "$PATCHDIR/g26.py"
control "g27 the ARGUMENT-LIST RANGE stop replaced by a guess" $CHECKER "$PATCHDIR/g27.py"
control "g28 isSignatureApplicable's ARGUMENT LOOP dropped" $CHECKER "$PATCHDIR/g28.py"
control "g29 the OMITTED-EXPRESSION skip dropped" $CHECKER "$PATCHDIR/g29.py"
control "g30 the CONTEXTUAL TYPE dropped from the argument check" $CHECKER "$PATCHDIR/g30.py"
control "g31 the `this`-TYPE row forced to fire" $CHECKER "$PATCHDIR/g31.py"
control "g32 the SPREAD-ARGUMENT-TYPE row dropped" $CHECKER "$PATCHDIR/g32.py"
control "g33 the LITERAL-OF-CONTEXTUAL UNION arm reverted to its row" $CHECKER "$PATCHDIR/g33.py"
control "g34 checkDeprecatedSignature back to its OLD row" $CHECKER "$PATCHDIR/g34.py"
control "g35 silentNeverSignature back to its row" $CHECKER "$PATCHDIR/g35.py"
control "g36 unknownSignature answering null" $CHECKER "$PATCHDIR/g36.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
