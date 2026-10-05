#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice102.sh — the slice-102 battery: THE ASSIGNABLE-TO-KIND TEST and
# the four arms it stands in front of.
#
# ★★★ THE SUCCESSOR SLICE 101 NAMED, AND ITS FIRST FINDING IS ABOUT THAT NAMING.
# The closing paragraph read *"`isTypeAssignableToKindEx` is TEN LINES whose only
# dependency is `isTypeAssignableTo` … ten lines buy the arm and the row at once"*.
# The ten lines are here and they answer; the ARM they were supposed to buy is only
# half bought, and the half that is missing was on slice 101's own NOT-IN-THIS-SLICE
# list. `checkArithmeticOperandType` asks one question — is the operand assignable
# to `numberOrBigIntType` — and that target is a UNION, so every call of it reaches
# `structuredTypeRelatedTo` and stops. TS2362 and TS2363 have NO INPUT under this
# port and it is the TARGET that decides that, not the operands. g19 is the row that
# proves it by minting the field as `numberType` alone.
#
# ★★★ THE FIFTEENTH INSTRUMENT, AND ITS ARGUMENT IS SLICE 101'S ONE PRODUCT ON. The
# RELPIN writes at checkTypeRelatedToAndOptionallyElaborate, which is NOT the entry
# this chapter uses: isTypeAssignableToKindEx reaches the relation through
# isTypeRelatedTo, below that pin, and most of its calls never reach the relation at
# all — the `source.flags & kind` fast path answers them, and an answer there writes
# no diagnostic, no type, no relation row and nothing in the stop log.
# `tscaly_types --kinds` prints `K <source flags> <kind> <strict> <arm> <verdict>`;
# `arm` is 0 the fast path, 1 the strict refusal, 2…11 the nine disjuncts in the
# reference's order, 12 the fall-through, and it is the column that makes a broken
# disjunct distinguishable from a disjunct with no input.
#
# ★★★ THE HAND COUNT THAT LICENSES THE NUMBERS BELOW: `--kinds` over the five pin
# files reads 56 rows, FIVE of the twelve arms (0 the fast path, 1 the strict
# refusal, 4 StringLike, 11 NonPrimitive, 12 the fall-through) and both values of
# `strict`; the whole-corpus KINDGATE reads 242 rows, 116 TRUE, 126 FALSE and — on
# every row of this battery — ZERO could-not-answer. ★★That fourth column being
# zero is a measurement and not a dead column: every target inside
# isTypeAssignableToKindEx is an intrinsic and answers. The one comparison that
# always stops is the one OUTSIDE it, checkArithmeticOperandType's union target,
# which is finding one and g15. Against all of it stand the 174 stop events the two
# named rows carried at stage 1 over 93 units.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice102.sh 2>&1 | tee /tmp/battery102.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice102.sh g17 g19` runs the baseline and
# then only the named rows. ★The baseline is NEVER skipped: every verdict below is
# a comparison against it.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Five files: the arithmetic and
# bitwise group with its boolean suggestion and its three result forks, the `+` arm
# with the STRICT flag that separates it from the one above, the prefix unary
# expression's two literal folds and its operator switch, the `++`/`--` tail both
# unary expressions share, and the for-in statement's TS2407 — the second and last
# isTypeAssignableToKind call site.
PINFILES="
$FIX/kind_arith.ts
$FIX/kind_plus.ts
$FIX/kind_unary.ts
$FIX/kind_increment.ts
$FIX/kind_forin.ts
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

WORK=$(mktemp -d -t tscaly-ctl102)

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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; REL_BASE=""; KIND_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — ten instruments"
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
  fnpin_of > "$WORK/base.fn"
  objpin_of > "$WORK/base.obj"
  mempin_of > "$WORK/base.mem"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.mts' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  REL_BASE=$(relgate)
  KIND_BASE=$(kindgate)
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
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             relgate   (rows related notrelated couldnotanswer checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $REL_BASE"
  echo "             kindgate  (rows true false couldnotanswer checksum) over the same units = $KIND_BASE"
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
  fnpin_of > "$WORK/ctl.fn"
  objpin_of > "$WORK/ctl.obj"
  mempin_of > "$WORK/ctl.mem"
  stop=$(stopgate)
  local rel_g kind_g
  rel_g=$(relgate)
  kind_g=$(kindgate)
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
    echo "  diagpin   unmoved — all five pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all five fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all five fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.rel" "$WORK/ctl.rel"; then
    echo "  relpin    unmoved — all five fixtures make the same comparisons, in order."
  else
    green "relpin    RED"
    diff "$WORK/base.rel" "$WORK/ctl.rel" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.kind" "$WORK/ctl.kind"; then
    echo "  kindpin   unmoved — all five fixtures ask the same kinds and take the same arms."
  else
    green "kindpin   RED"
    diff "$WORK/base.kind" "$WORK/ctl.kind" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.fn" "$WORK/ctl.fn"; then
    echo "  fnpin     unmoved — all five fixtures decide the same way, in the same order."
  else
    green "fnpin     RED"
    diff "$WORK/base.fn" "$WORK/ctl.fn" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.obj" "$WORK/ctl.obj"; then
    echo "  objpin    unmoved — all five fixtures build the same object-literal types."
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
    echo "  mempin    unmoved — all five fixtures resolve the same members."
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
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all ten, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL TEN AND NOTHING MOVED AT ALL."
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

P['g01'] = ('''# THE PREMISE — the ARITHMETIC AND BITWISE arm reverted to the stop it carried.
# PREDICTION: everything this half of the slice does, in one row.''',
'''old = """        if Checker.is_arithmetic_or_bitwise_operator(op_kind)
        {
            if Checker.either_is(left_type, right_type, silent_never_type)
                return silent_never_type
            if left_type = null"""
new = """        if Checker.is_arithmetic_or_bitwise_operator(op_kind)
        {
            this.record_unported("check-arithmetic-operand-type", op_kind)
            return null
        }
        if false
        {
            if Checker.either_is(left_type, right_type, silent_never_type)
                return silent_never_type
            if left_type = null"""''')

P['g02'] = ('''# The `+` and `+=` arm reverted to its stop. PREDICTION: the kindgate loses every
# STRICT row — this arm is the only strict caller in the port — and the three
# result forks stop answering.''',
'''old = """        if Checker.is_plus_operator(op_kind)
        {
            if Checker.either_is(left_type, right_type, silent_never_type)
                return silent_never_type
            if left_type = null"""
new = """        if Checker.is_plus_operator(op_kind)
        {
            this.record_unported("is-type-assignable-to-kind", op_kind)
            return null
        }
        if false
        {
            if Checker.either_is(left_type, right_type, silent_never_type)
                return silent_never_type
            if left_type = null"""''')

P['g03'] = ('''# The for-in statement's TS2407 reverted to its stop. PREDICTION: the three TS2407
# lines this slice adds at stage 1 are exactly this row, and it is the only call
# site of isTypeAssignableToKind outside the binary expression.''',
'''old = """        if right_type = null
            this.record_unported("is-type-assignable-to-kind", AstNode.kind_of(node))
        else
        {
            let rt right_type as ref[Type]"""
new = """        if right_type <> null
            this.record_unported("is-type-assignable-to-kind", AstNode.kind_of(node))
        if false
        {
            let rt right_type as ref[Type]"""''')

P['g04'] = ('''# The PREFIX unary expression reverted to its stop. PREDICTION: 44 events over 26
# units at stage 1 come back, and with them every literal fold — `-1` stops being a
# NumberLiteral type of value −1.''',
'''old = """        if k = KindPrefixUnaryExpression
            return this.check_prefix_unary_expression(node)"""
new = """        if k = KindPrefixUnaryExpression
        {
            this.record_unported("check-prefix-unary-expression", k)
            return null
        }"""''')

P['g05'] = ('''# The POSTFIX unary expression reverted to its stop. PREDICTION: 21 events over 14
# units, and NO diagnostic — the report it gates is unreachable behind
# checkArithmeticOperandType's wall (g15).''',
'''old = """        if k = KindPostfixUnaryExpression
            return this.check_postfix_unary_expression(node)"""
new = """        if k = KindPostfixUnaryExpression
        {
            this.record_unported("check-postfix-unary-expression", k)
            return null
        }"""''')

P['g06'] = ('''# isTypeAssignableToKindEx's FLAGS FAST PATH dropped. PREDICTION: the largest row
# in the battery. It is the path that answers `1 + 1`, `"a" + "b"` and every other
# well-typed operand pair without ever reaching the relation; without it every one
# of them falls through to a disjunct whose target is an intrinsic and answers
# FALSE or stops.''',
'''old = """        if (source.flags & kind) <> 0
            return this.record_kind(source, kind, strict_bit, 0, mark, true)"""
new = """        if false
            return this.record_kind(source, kind, strict_bit, 0, mark, true)"""''')

P['g07'] = ('''# The STRICT refusal dropped, so isTypeAssignableToKindEx(strict) answers what
# isTypeAssignableToKind does. PREDICTION: `any + any` answers NUMBER instead of
# ANY — the one line the strict flag exists for, and the commonest input there is.''',
'''old = """        if strict
        {
            if (source.flags & (TypeFlagsAnyOrUnknown | TypeFlagsVoid | TypeFlagsUndefined | TypeFlagsNull)) <> 0
                return this.record_kind(source, kind, strict_bit, 1, mark, false)
        }"""
new = """        if false
        {
            if (source.flags & (TypeFlagsAnyOrUnknown | TypeFlagsVoid | TypeFlagsUndefined | TypeFlagsNull)) <> 0
                return this.record_kind(source, kind, strict_bit, 1, mark, false)
        }"""''')

P['g08'] = ('''# The NumberLike disjunct dropped. PREDICTION: it is reached only where the flag
# mask did NOT already overlap, i.e. where the source is not itself number-like —
# and then its target is the numberType intrinsic and the relation can answer.''',
'''old = """        if (kind & TypeFlagsNumberLike) <> 0
        {
            if this.is_type_assignable_to(source, number_type)
                return this.record_kind(source, kind, strict_bit, 2, mark, true)
        }"""
new = """        if false
        {
            if this.is_type_assignable_to(source, number_type)
                return this.record_kind(source, kind, strict_bit, 2, mark, true)
        }"""''')

P['g09'] = ('''# The BigIntLike disjunct dropped. PREDICTION: bothAreBigIntLike is its only
# heavy reader, so what moves is the arithmetic arm's SECOND result fork.''',
'''old = """        if (kind & TypeFlagsBigIntLike) <> 0
        {
            if this.is_type_assignable_to(source, bigint_type)
                return this.record_kind(source, kind, strict_bit, 3, mark, true)
        }"""
new = """        if false
        {
            if this.is_type_assignable_to(source, bigint_type)
                return this.record_kind(source, kind, strict_bit, 3, mark, true)
        }"""''')

P['g10'] = ('''# The StringLike disjunct dropped. PREDICTION: the `+` arm's non-strict gate in
# front of checkNonNullType and its third strict fork both change answer; `any +
# "a"` is the shape that reaches this disjunct rather than the fast path.''',
'''old = """        if (kind & TypeFlagsStringLike) <> 0
        {
            if this.is_type_assignable_to(source, string_type)
                return this.record_kind(source, kind, strict_bit, 4, mark, true)
        }"""
new = """        if false
        {
            if this.is_type_assignable_to(source, string_type)
                return this.record_kind(source, kind, strict_bit, 4, mark, true)
        }"""''')

P['g11'] = ('''# The NonPrimitive disjunct dropped. PREDICTION: it is the for-in test's own
# disjunct and nothing else asks for that bit — TS2407 fires on every for-in.''',
'''old = """        if (kind & TypeFlagsNonPrimitive) <> 0
        {
            if this.is_type_assignable_to(source, non_primitive_type)
                return this.record_kind(source, kind, strict_bit, 11, mark, true)
        }"""
new = """        if false
        {
            if this.is_type_assignable_to(source, non_primitive_type)
                return this.record_kind(source, kind, strict_bit, 11, mark, true)
        }"""''')

P['g12'] = ('''# The SIX disjuncts no caller's kind word reaches, dropped together — BooleanLike,
# Void, Never, Null, Undefined and ESSymbol. PREDICTION: UNGATED, and the argument
# is a closed list rather than a corpus: this port has exactly two call sites and
# five kind words between them (AnyOrUnknown, NumberLike, BigIntLike, StringLike,
# NonPrimitive|InstantiableNonPrimitive), and not one of them carries any of these
# six bits. They are transcribed for the slice that adds a third call site.''',
'''old = """        if (kind & TypeFlagsBooleanLike) <> 0"""
new = """        if false"""''')

P['g13'] = ('''# The FALL-THROUGH answers TRUE instead of FALSE. PREDICTION: every question this
# function cannot answer becomes a yes — which for the for-in is TS2407 lost, and
# for the `+` arm is `number` where the reference answers `any`.''',
'''old = """        this.record_kind(source, kind, strict_bit, 12, mark, false)
    }"""
new = """        this.record_kind(source, kind, strict_bit, 12, mark, true)
    }"""''')

P['g14'] = ('''# checkArithmeticOperandType's MARK GUARD removed: it reports whenever the
# comparison did not answer TRUE, without asking whether it answered at all.
# PREDICTION: diagcheck RED by INVENTION on a large scale — under this port EVERY
# call of it stops (see g15), so this row turns the whole population into TS2362
# and TS2363 lines the reference does not have.''',
'''old = """        if this.unported_mark() <> mark
            return false
        this.error_on_node(operand, diagnostic)"""
new = """        this.error_on_node(operand, diagnostic)"""''')

P['g15'] = ('''# THE FINDING-ONE ROW. numberOrBigIntType minted as numberType ALONE instead of the
# union. PREDICTION: it is not a defect control, it is the PROOF that the target
# and not the operands is what walls TS2362/TS2363 — with an intrinsic target the
# relation answers, `check_arithmetic_operand_type` starts returning true, the 66
# `structured-type-related-to` events this slice added disappear, and both reports
# and the whole assignment tail come alive at once. It must be REVERTED, not kept:
# `number|bigint` is the reference's type and `number` is not.''',
'''old = """        set number_or_bigint_type: this.get_union_type_pair(number_type, bigint_type)"""
new = """        set number_or_bigint_type: number_type"""''')

P['g16'] = ('''# The AnyOrUnknown pair dropped from the arithmetic result fork, so the fork is
# decided by the maybeTypeOfKind pair alone. PREDICTION: nothing, and the reason is
# a SUBSUMPTION rather than an absence — a source that is any or unknown is not
# BigIntLike either, so the second disjunct answers the same TRUE the first would.
# It becomes gateable the day a union of `any` and a bigint can be built.''',
'''old = """            var use_number false
            if this.is_type_assignable_to_kind(lt, TypeFlagsAnyOrUnknown)
            {
                if this.is_type_assignable_to_kind(rt, TypeFlagsAnyOrUnknown)
                    set use_number: true
            }"""
new = """            var use_number false"""''')

P['g17'] = ('''# The maybeTypeOfKind BigIntLike pair dropped, so only the AnyOrUnknown pair can
# choose number. PREDICTION: every ordinary `a * b` over numbers stops answering
# number and falls into the bigint fork or the report.''',
'''old = """            if use_number = false
            {
                if Checker.maybe_type_of_kind(lt, TypeFlagsBigIntLike) = false
                {
                    if Checker.maybe_type_of_kind(rt, TypeFlagsBigIntLike) = false
                        set use_number: true
                }
            }"""
new = """            if false
            {
                set use_number: true
            }"""''')

P['g18'] = ('''# bothAreBigIntLike ignores its RIGHT operand. PREDICTION: `1n * 1` answers bigint
# where the reference reports — the asymmetric input is what separates the two
# halves of a conjunction, and a fixture with only symmetric pairs cannot see it.''',
'''old = """        if this.is_type_assignable_to_kind(left, TypeFlagsBigIntLike) = false
            return false
        this.is_type_assignable_to_kind(right, TypeFlagsBigIntLike)"""
new = """        this.is_type_assignable_to_kind(left, TypeFlagsBigIntLike)"""''')

P['g19'] = ('''# The `>>>` report on a BigInt pair dropped. PREDICTION: `1n >>> 1n` loses its
# TS2365 and answers bigint silently — one line in the arith fixture, and the only
# report the arithmetic arm produces today that is NOT behind g15's wall.''',
'''old = """                    if unsigned_shift
                        this.report_operator_error(lt, op_kind, rt, error_node)"""
new = """                    if false
                        this.report_operator_error(lt, op_kind, rt, error_node)"""''')

P['g20'] = ('''# The `**` / ES2016 fork dropped. PREDICTION: UNGATED and DEAD, with the number
# that is its whole content: language_version is ES2025 = 12 and the guard is
# `< 3`, so TS2791 cannot be collected under this harness. The row is what makes
# "dead" a measurement rather than a reading of the constant.''',
'''old = """                    if exponent
                    {
                        ; Dead under this harness — see ScriptTargetES2016's note.
                        if language_version < ScriptTargetES2016"""
new = """                    if false
                    {
                        ; Dead under this harness — see ScriptTargetES2016's note.
                        if language_version < ScriptTargetES2016"""''')

P['g21'] = ('''# The arithmetic arm's third fork reports nothing and still answers errorType.
# PREDICTION: a report LOST — the direction a SUBSEQUENCE relation cannot see — so
# the row is expected to move the diagpin and the diagcheck COUNT rather than its
# colour.''',
'''old = """                    this.report_operator_error(lt, op_kind, rt, error_node)
                    set result_type: error_type"""
new = """                    set result_type: error_type"""''')

P['g22'] = ('''# The `left_ok && right_ok` tail gate ignored, so checkAssignmentOperator and the
# shift row run whatever the two operand checks concluded. PREDICTION: it is the
# OTHER half of g15 — under this port both answers are false today, so this row
# says how much is waiting behind that one wall.''',
'''old = """            if left_ok
            {
                if right_ok
                {
                    this.check_assignment_operator(left, op_kind, right, lt, result_type)
                    if Checker.is_shift_operator(op_kind)
                        this.record_unported("evaluate-shift-operand", op_kind)
                }
            }"""
new = """            this.check_assignment_operator(left, op_kind, right, lt, result_type)
            if Checker.is_shift_operator(op_kind)
                this.record_unported("evaluate-shift-operand", op_kind)"""''')

P['g23'] = ('''# The arithmetic FORK MARK guard removed, so a fork chosen on a comparison that
# stopped is answered and reported anyway. PREDICTION: diagcheck RED by INVENTION —
# this is the guard that keeps a could-not-answer from becoming a TS2365.''',
'''old = """            if this.unported_mark() <> fork_mark
                return null
            if left_ok"""
new = """            if left_ok"""''')

P['g24'] = ('''# The BOOLEAN SUGGESTION dropped. PREDICTION: three TS2447 lines in the arith
# fixture go, and the arm answers through its result fork instead of returning
# number early.''',
'''old = """                    let suggested Checker.get_suggested_boolean_operator(op_kind)
                    if suggested <> KindUnknown"""
new = """                    let suggested Checker.get_suggested_boolean_operator(op_kind)
                    if false"""''')

P['g25'] = ('''# The `+` arm's non-strict StringLike gate forced TRUE, so checkNonNullType never
# runs on either operand. PREDICTION: it changes WHICH type the three strict forks
# see, not whether they run — a nullable operand keeps its null.''',
'''old = """            var either_string false
            if this.is_type_assignable_to_kind(lt, TypeFlagsStringLike)
                set either_string: true
            else
            {
                if this.is_type_assignable_to_kind(rt, TypeFlagsStringLike)
                    set either_string: true
            }"""
new = """            var either_string true"""''')

P['g26'] = ('''# The `+` arm's three forks made NON-strict. PREDICTION: the sharpest row in the
# battery and the one the strict flag exists for — `any + any` answers NUMBER
# instead of ANY, because a non-strict NumberLike question lets `any` through
# isSimpleTypeRelatedTo's very first arm. One flag, one line apart in the
# reference.''',
'''old = """            if this.is_type_assignable_to_kind_ex(lt, TypeFlagsNumberLike, true)
            {
                if this.is_type_assignable_to_kind_ex(rt, TypeFlagsNumberLike, true)
                    set result_type: number_type
            }"""
new = """            if this.is_type_assignable_to_kind_ex(lt, TypeFlagsNumberLike, false)
            {
                if this.is_type_assignable_to_kind_ex(rt, TypeFlagsNumberLike, false)
                    set result_type: number_type
            }"""''')

P['g27'] = ('''# The `+` arm's NumberLike fork dropped. PREDICTION: `1 + 2` answers through the
# STRING fork or the any tail instead of number.''',
'''old = """            var result_type: ref[Type]? null
            ; "Operands of an enum type are treated as having the primitive type
            ; Number. If both operands are of the Number primitive type, the result
            ; is of the Number primitive type."
            if this.is_type_assignable_to_kind_ex(lt, TypeFlagsNumberLike, true)"""
new = """            var result_type: ref[Type]? null
            ; "Operands of an enum type are treated as having the primitive type
            ; Number. If both operands are of the Number primitive type, the result
            ; is of the Number primitive type."
            if false"""''')

P['g28'] = ('''# The `+` arm's BigIntLike fork dropped. PREDICTION: `1n + 2n` answers through the
# any tail instead of bigint, and the fixture's own line is the only input.''',
'''old = """                if this.is_type_assignable_to_kind_ex(lt, TypeFlagsBigIntLike, true)
                {
                    if this.is_type_assignable_to_kind_ex(rt, TypeFlagsBigIntLike, true)
                        set result_type: bigint_type
                }"""
new = """                if false
                {
                    if this.is_type_assignable_to_kind_ex(rt, TypeFlagsBigIntLike, true)
                        set result_type: bigint_type
                }"""''')

P['g29'] = ('''# The `+` arm's StringLike fork dropped. PREDICTION: `"a" + "b"` reaches the any
# tail, which for two string literals answers NOTHING — resultType stays nil and
# the arm REPORTS TS2365 on ordinary string concatenation.''',
'''old = """                var either_string_strict false
                if this.is_type_assignable_to_kind_ex(lt, TypeFlagsStringLike, true)
                    set either_string_strict: true
                else
                {
                    if this.is_type_assignable_to_kind_ex(rt, TypeFlagsStringLike, true)
                        set either_string_strict: true
                }"""
new = """                var either_string_strict false"""''')

P['g30'] = ('''# The `+` arm's IsTypeAny arm dropped. PREDICTION: `any + any`, which the strict
# forks all refuse, loses its answer and collects a TS2365 instead.''',
'''old = """                var either_any false
                if Checker.is_type_any(lt)
                    set either_any: true
                if Checker.is_type_any(rt)
                    set either_any: true"""
new = """                var either_any false"""''')

P['g31'] = ('''# The `+` arm's isErrorType fork dropped, so an error-typed operand answers `any`
# rather than the error type. PREDICTION: the reference's own note says the two
# were once one — *"unknown type here denotes error type. Old compiler treated this
# case as any type so do we"* — so what separates them is what the NEXT chapter
# does with the answer.''',
'''old = """                    var either_error false
                    if this.is_error_type(lt)
                        set either_error: true
                    if this.is_error_type(rt)
                        set either_error: true"""
new = """                    var either_error false"""''')

P['g32'] = ('''# THE DEFECT THIS SLICE MADE AND CAUGHT, put back. checkForDisallowedESSymbol
# Operand answers TRUE when it did NOT report, so the reference's `resultType != nil
# && !c.checkFor…` returns early exactly when a symbol operand DID collect TS2469.
# Written the natural way round the early return fires for every well-typed `+` and
# the `+=` assignment check never runs. PREDICTION: no diagnostic moves at stage 1
# and the arm is silently wrong — which is why the row exists.''',
'''old = """                if this.check_for_disallowed_es_symbol_operand(left, right, lt, rt, op_kind) = false
                    return result_type as ref[Type]"""
new = """                if this.check_for_disallowed_es_symbol_operand(left, right, lt, rt, op_kind)
                    return result_type as ref[Type]"""''')

P['g33'] = ('''# The `+` arm's second MARK guard removed, so a result type chosen on a comparison
# that stopped is answered, and a nil one REPORTS. PREDICTION: the same invention
# direction as g23, over the other arm.''',
'''old = """            ; REPORT — the one direction diagcheck can see.
            if this.unported_mark() <> arm_mark
                return null"""
new = """            ; REPORT — the one direction diagcheck can see."""''')

P['g34'] = ('''# The prefix arm's NUMERIC-LITERAL fold dropped. PREDICTION: `-1` stops being a
# NumberLiteral type of value −1 and becomes plain `number` through
# getUnaryResultType — a WRONG ANSWER at rc 0 that no diagnostic can show, and the
# reason the fold sits in FRONT of the operator switch.''',
'''old = """        let ok AstNode.kind_of(expr)
        if ok = KindNumericLiteral"""
new = """        let ok AstNode.kind_of(expr)
        if false"""''')

P['g35'] = ('''# jsnum_negate replaced by the IDENTITY. PREDICTION: `-1` answers the type of `1`.
# It is the sharpest wrong answer in the slice and the one furthest from any
# diagnostic — the row exists because a sign bit has no report of its own.''',
'''old = """function jsnum_negate(bits: u64) returns u64
    bits xor ((1 as u64) << 63)"""
new = """function jsnum_negate(bits: u64) returns u64
    bits"""''')

P['g36'] = ('''# The prefix arm's BIGINT-LITERAL fold dropped. PREDICTION: `-1n` loses its sign
# and answers `bigint` through getUnaryResultType — the one place in the whole port
# where a PseudoBigInt is minted with Negative set.''',
'''old = """        if ok = KindBigIntLiteral
        {
            if op_kind = KindMinusToken
                return this.bigint_literal_arm(expr, true)
        }"""
new = """        if false
        {
            if op_kind = KindMinusToken
                return this.bigint_literal_arm(expr, true)
        }"""''')

P['g37'] = ('''# The prefix arm's ESSymbolLike report dropped. PREDICTION: UNGATED — a
# symbol-typed operand needs the globals table (§3.11), which is the same wall
# slice 101's g14 measured from the relation's side.''',
'''old = """            if this.maybe_type_of_kind_considering_base_constraint(ot, TypeFlagsESSymbolLike)
                this.error_on_node(expr, DiagThe_0_operator_cannot_be_applied_to_type_symbol)"""
new = """            if false
                this.error_on_node(expr, DiagThe_0_operator_cannot_be_applied_to_type_symbol)"""''')

P['g38'] = ('''# The `+`-on-a-bigint TS2736 dropped. PREDICTION: `+1n` loses its report and still
# answers number — one line in the unary fixture, and the only report the prefix
# arm produces that does not need a table.''',
'''old = """                if this.maybe_type_of_kind_considering_base_constraint(ot, TypeFlagsBigIntLike)
                    this.error_on_node(expr, DiagOperator_0_cannot_be_applied_to_type_1)"""
new = """                if false
                    this.error_on_node(expr, DiagOperator_0_cannot_be_applied_to_type_1)"""''')

P['g39'] = ('''# The `!` operator's TypeFacts fork always answers booleanType. PREDICTION: `!true`
# stops answering the FALSE literal type — a narrowing this port has had since
# slice 90 and which nothing but a later chapter reads.''',
'''old = """            let facts this.get_type_facts(ot, TypeFactsTruthy | TypeFactsFalsy)
            if facts = TypeFactsTruthy
                return false_type
            if facts = TypeFactsFalsy
                return true_type"""
new = """            let facts this.get_type_facts(ot, TypeFactsTruthy | TypeFactsFalsy)"""''')

P['g40'] = ('''# getUnaryResultType's AnyOrUnknown / NumberLike test dropped, so a BigIntLike
# operand always answers bigint. PREDICTION: it is the third reader of
# numberOrBigIntType and the only one that can ANSWER with it, so this row is what
# says the field has a live consumer that g15 does not cover.''',
'''old = """            var number_like false
            if this.is_type_assignable_to_kind(operand_type, TypeFlagsAnyOrUnknown)
                set number_like: true
            else
            {
                if Checker.maybe_type_of_kind(operand_type, TypeFlagsNumberLike)
                    set number_like: true
            }"""
new = """            var number_like false"""''')

P['g41'] = ('''# check_increment_operand's `ok` gate ignored, so checkReferenceExpression runs
# whatever checkArithmeticOperandType concluded. PREDICTION: the increment
# fixture's `(0)++` and `--(1)` collect TS2357 — which under this port they cannot
# today, for g15's reason and no other. It is the third row that prices the same
# wall, and the three together are how much of this chapter is waiting on it.''',
'''old = """        if this.check_arithmetic_operand_type(operand, t as ref[Type], DiagAn_arithmetic_operand_must_be_of_type_any_number_bigint_or_an_enum_type) = false
            return"""
new = """        this.check_arithmetic_operand_type(operand, t as ref[Type], DiagAn_arithmetic_operand_must_be_of_type_any_number_bigint_or_an_enum_type)"""''')

P['g42'] = ('''# THE ERROR-TYPE GUARD in checkArithmeticOperandType removed — the defect STAGE 2
# found and stage 1 could not. `error_type` carries TypeFlagsAny and the assignable
# block's `s&Any` arm answers TRUE against every target, so an operand whose type
# this port could not compute comes back ASSIGNABLE, opens the `ok` gate and runs
# checkReferenceExpression on it. PREDICTION: UNGATED AT STAGE 1 and diagcheck RED
# at STAGE 2 — two units of 18 304 where `++(S + S)` over an unresolved `S` collects
# a TS2357 the reference does not have. It is slice 101's finding one with the
# polarity reversed, and the row that says a battery run only at stage 1 would have
# shipped it a second time.''',
'''old = """        if this.is_error_type(t)
        {
            this.record_unported("arithmetic-operand-error-type", diagnostic)
            return false
        }
        let mark this.unported_mark()"""
new = """        let mark this.unported_mark()"""''')

for k, (doc, body) in P.items():
    with open(os.path.join(D, k + '.py'), 'w') as f:
        f.write(doc + '\n')
        f.write('import sys\n')
        f.write(body + '\n')
        f.write("""
path = sys.argv[1]
s = open(path).read()
if s.count(old) != 1:
    sys.stderr.write("anchor count %d for %s\\n" % (s.count(old), path))
    sys.exit(1)
open(path, 'w').write(s.replace(old, new))
""")
MKPATCHES

baseline

control "g01 THE PREMISE (the ARITHMETIC and BITWISE arm) reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the + and += arm reverted to its stop" $CHECKER "$PATCHDIR/g02.py"
control "g03 the for-in statement's TS2407 reverted to its stop" $CHECKER "$PATCHDIR/g03.py"
control "g04 the PREFIX unary expression reverted to its stop" $CHECKER "$PATCHDIR/g04.py"
control "g05 the POSTFIX unary expression reverted to its stop" $CHECKER "$PATCHDIR/g05.py"
control "g06 the FLAGS FAST PATH dropped" $CHECKER "$PATCHDIR/g06.py"
control "g07 the STRICT refusal dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 the NumberLike disjunct dropped" $CHECKER "$PATCHDIR/g08.py"
control "g09 the BigIntLike disjunct dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 the StringLike disjunct dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the NonPrimitive disjunct dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the six disjuncts no caller's kind word reaches, dropped together" $CHECKER "$PATCHDIR/g12.py"
control "g13 the FALL-THROUGH answers TRUE instead of FALSE" $CHECKER "$PATCHDIR/g13.py"
control "g14 checkArithmeticOperandType's MARK GUARD removed" $CHECKER "$PATCHDIR/g14.py"
control "g15 numberOrBigIntType minted as numberType ALONE (the finding-one row)" $CHECKER "$PATCHDIR/g15.py"
control "g16 the AnyOrUnknown pair dropped from the arithmetic result fork" $CHECKER "$PATCHDIR/g16.py"
control "g17 the maybeTypeOfKind BigIntLike pair dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 bothAreBigIntLike's RIGHT operand ignored" $CHECKER "$PATCHDIR/g18.py"
control "g19 the unsigned-shift report on a BigInt pair dropped" $CHECKER "$PATCHDIR/g19.py"
control "g20 the exponent / ES2016 fork dropped (predicted DEAD)" $CHECKER "$PATCHDIR/g20.py"
control "g21 the arithmetic else-branch's reportOperatorError dropped" $CHECKER "$PATCHDIR/g21.py"
control "g22 the left_ok and right_ok tail gate ignored" $CHECKER "$PATCHDIR/g22.py"
control "g23 the arithmetic FORK MARK guard removed" $CHECKER "$PATCHDIR/g23.py"
control "g24 the BOOLEAN SUGGESTION dropped" $CHECKER "$PATCHDIR/g24.py"
control "g25 the + arm's non-strict StringLike gate forced TRUE" $CHECKER "$PATCHDIR/g25.py"
control "g26 the + arm's NumberLike fork made NON-strict" $CHECKER "$PATCHDIR/g26.py"
control "g27 the + arm's NumberLike fork dropped" $CHECKER "$PATCHDIR/g27.py"
control "g28 the + arm's BigIntLike fork dropped" $CHECKER "$PATCHDIR/g28.py"
control "g29 the + arm's StringLike fork dropped" $CHECKER "$PATCHDIR/g29.py"
control "g30 the + arm's IsTypeAny arm dropped" $CHECKER "$PATCHDIR/g30.py"
control "g31 the + arm's isErrorType fork dropped" $CHECKER "$PATCHDIR/g31.py"
control "g32 the ES-SYMBOL polarity inverted (the defect this slice made and caught)" $CHECKER "$PATCHDIR/g32.py"
control "g33 the + arm's second MARK guard removed" $CHECKER "$PATCHDIR/g33.py"
control "g34 the prefix arm NUMERIC-LITERAL fold dropped" $CHECKER "$PATCHDIR/g34.py"
control "g35 jsnum_negate replaced by the IDENTITY" $PKG/0.1.0/tscaly/jsnum.scaly "$PATCHDIR/g35.py"
control "g36 the prefix arm's BIGINT-LITERAL fold dropped" $CHECKER "$PATCHDIR/g36.py"
control "g37 the prefix arm's ESSymbolLike report dropped" $CHECKER "$PATCHDIR/g37.py"
control "g38 the plus-on-a-bigint TS2736 dropped" $CHECKER "$PATCHDIR/g38.py"
control "g39 the ! operator's TypeFacts fork always answers booleanType" $CHECKER "$PATCHDIR/g39.py"
control "g40 getUnaryResultType's AnyOrUnknown / NumberLike test dropped" $CHECKER "$PATCHDIR/g40.py"
control "g41 check_increment_operand's ok gate ignored" $CHECKER "$PATCHDIR/g41.py"
control "g42 the ERROR-TYPE GUARD in checkArithmeticOperandType removed" $CHECKER "$PATCHDIR/g42.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
