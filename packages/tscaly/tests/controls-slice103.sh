#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice103.sh — the slice-103 battery: THE STRUCTURED FORK and the union
# relation behind it.
#
# ★★★ THE SUCCESSOR SLICE 102 NAMED, AND ITS FIRST FINDING IS THAT THE PRICE WAS
# PUT ON THE WRONG DOOR. That closing paragraph read *"the thing that removes all
# three rows is `unionOrIntersectionRelatedTo`s target half — `typeRelatedToSomeType`
# — which needs `recursiveTypeRelatedTo`, the relation cache and `getRelationKey`
# under it. That is the honest successor and it is a chapter rather than ten
# lines."* The references own `skipCaching` line says otherwise: a comparison
# whose TARGET is a union of fewer than four constituents and whose SOURCE is not
# structured reaches `unionOrIntersectionRelatedTo` DIRECTLY, past the cache and
# past the recursion — and that is exactly the shape `checkArithmeticOperandType`
# makes, every time, with `number|bigint`. g08 and g10 are the two rows that price
# the threshold; g01 is the premise.
#
# ★★★ THE SIXTEENTH INSTRUMENT, AND ITS ARGUMENT IS THAT THIS SLICE REMOVES THE
# ONLY THING THAT COULD SEE ITS OWN POPULATION. Until now the structured branch
# was ONE `record_unported`, so the work list WAS the instrument; this slice
# answers 105 of the corpuss 117 arrivals there, and an answer writes no
# diagnostic, no type and — once the stop is gone — nothing in the stop log
# either. The RELPIN cannot stand in (it sits at
# checkTypeRelatedToAndOptionallyElaborate, two levels above the arithmetic
# operand check) and neither can the KINDPIN (that call does not go through
# isTypeAssignableToKindEx at all, which is slice 102s own finding one).
# `tscaly_types --forks` prints `F <source flags> <target flags> <route> <branch>
# <verdict>`; `route` is 0 the excess-property stop, 1 the common-property stop,
# 2 the union relation and 3 the recursion, and `branch` is which arm of
# unionOrIntersectionRelatedTo answered.
#
# ★★★ THE HAND COUNT THAT LICENSES THE NUMBERS BELOW: `--forks` over the three pin
# files reads 15 rows over all FOUR routes and both non-stop verdicts; the
# whole-corpus FORKGATE reads 117 rows, 90 TRUE, 15 FALSE and 12 COULD-NOT-ANSWER
# — and the twelve are exactly the ten route-0/route-1 rows plus the two route-3
# rows, which is the instruments own internal gate and needs no reference.
# ★★Route 3 is TWO, and both are this batterys own fixtures: the corpus
# contributes ZERO. The recursion has no input at stage 1, and the branch column
# says the same thing about five of the six arms of the union relation.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64s rule, and slice
# 101 is why it is not optional: the guard its finding one is about was invisible
# to the whole small corpus.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice103.sh 2>&1 | tee /tmp/battery103.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice103.sh g08 g10` runs the baseline
# and then only the named rows. ★The baseline is NEVER skipped: every verdict
# below is a comparison against it.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule). THREE files, and there is no fourth
# because there is no fourth mechanism with an input: the TARGET-union arm, which
# is the only arm of unionOrIntersectionRelatedTo the corpus takes; the
# PRIMITIVE-UNION short circuit inside it, with both of the exclusions the
# reference's own comment names; and the three routes out of the fork that are not
# the union relation at all.
#
# ★★★ THE SOURCE-UNION ARMS HAVE NO FIXTURE AND THAT IS A MEASUREMENT, NOT AN
# OMISSION. A union reaches the SOURCE side only through a value whose type is one,
# and under this port no identifier reference resolves at all (§3.11,
# `resolve-name-not-found`) and `checkConditionalExpression` is a stop — so
# `declare var u: number|string; var x: boolean = u` produces no comparison
# whatever. Three shapes were tried and each stopped one chapter earlier. g11 and
# g24 are the rows that say so with a number instead of a sentence.
PINFILES="
$FIX/fork_target_union.ts
$FIX/fork_primitive_union.ts
$FIX/fork_routes.ts
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

# ★★★ THE FORKPIN — slice 103's instrument; the argument is in ForkEvent's own
# header. `F <source flags> <target flags> <route> <branch> <verdict>` per call of
# the structured branch of isRelatedToEx. It exists because this slice REMOVES the
# only instrument that could see its own population: until now that branch was one
# `record_unported`, so the stop histogram WAS the pin, and an answer leaves no
# diagnostic, no type and nothing in the stop log.
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; REL_BASE=""; KIND_BASE=""; FORK_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — eleven instruments"
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
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.mts' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  REL_BASE=$(relgate)
  KIND_BASE=$(kindgate)
  FORK_BASE=$(forkgate)
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
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             relgate   (rows related notrelated couldnotanswer checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $REL_BASE"
  echo "             kindgate  (rows true false couldnotanswer checksum) over the same units = $KIND_BASE"
  echo "             forkgate  (rows true false couldnotanswer checksum | routes | branches) = $FORK_BASE"
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
  stop=$(stopgate)
  local rel_g kind_g fork_g
  rel_g=$(relgate)
  kind_g=$(kindgate)
  fork_g=$(forkgate)
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
  if cmp -s "$WORK/base.fork" "$WORK/ctl.fork"; then
    echo "  forkpin   unmoved — all three fixtures take the same routes and answer the same."
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
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all twelve, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL TWELVE AND NOTHING MOVED AT ALL."
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

P['g01'] = ('''# THE PREMISE — the whole structured branch reverted to the ONE stop it carried
# through slices 101 and 102. PREDICTION: this slice, in one row. The FORKGATE
# goes to zero rows, because the instrument sits inside the branch this removes.''',
'''old = """            ; ★★★ THE FORK, AND SLICE 102's CLOSING PARAGRAPH PRICED IT AT THE"""
new = """            this.record_unported("structured-type-related-to", source.flags)
            return false
            ; ★★★ THE FORK, AND SLICE 102's CLOSING PARAGRAPH PRICED IT AT THE"""''')

P['g02'] = ('''# The excess-property GUARD forced FALSE — the check never opens. PREDICTION: the
# seven route-0 rows are redistributed, not lost: a fresh object literal against an
# object target has nowhere to go but the common-property check or the recursion.''',
'''old = """                    if (source.object_flags & ObjectFlagsFreshLiteral) <> 0
                        set excess: true"""
new = """                    if (source.object_flags & ObjectFlagsFreshLiteral) <> 0
                        set excess: false"""''')

P['g03'] = ('''# The excess-property guard forced TRUE — every structured comparison stops there.
# PREDICTION: route 0 swallows the whole population and the slice is gone twice
# over, which is what separates a guard with input from a guard without.''',
'''old = """            var excess false
            if (intersection_state & IntersectionStateTarget) = 0"""
new = """            var excess true
            if (intersection_state & IntersectionStateTarget) = 0"""''')

P['g04'] = ('''# The common-property conjunction's TARGET test dropped. PREDICTION: the sharpest
# row in the battery — that one conjunct is what keeps this slice's ENTIRE
# population out of a report, because a UNION target carries neither Object nor
# Intersection and fails it outright.''',
'''old = """            if (target.flags & (TypeFlagsObject | TypeFlagsIntersection)) = 0
                set common: false"""
new = """            if (target.flags & (TypeFlagsObject | TypeFlagsIntersection)) = 0
                set common: common"""''')

P['g05'] = ('''# The common-property conjunction's SOURCE test dropped. PREDICTION: smaller than
# g04 and in the same direction — the arithmetic population's source is a literal,
# which IS Primitive, so this conjunct never refutes it.''',
'''old = """            if (source.flags & (TypeFlagsPrimitive | TypeFlagsObject | TypeFlagsIntersection)) = 0
                set common: false"""
new = """            if (source.flags & (TypeFlagsPrimitive | TypeFlagsObject | TypeFlagsIntersection)) = 0
                set common: common"""''')

P['g06'] = ('''# The intersectionState conjunct dropped from the EXCESS check. PREDICTION:
# UNGATED — nothing in this port mints an intersection, so no caller ever sets the
# target bit and the conjunct is always true. Transcribed for the slice that adds
# typeRelatedToEachType.''',
'''old = """            if (intersection_state & IntersectionStateTarget) = 0
            {
                if Checker.is_object_literal_type(source)"""
new = """            if 0 = 0
            {
                if Checker.is_object_literal_type(source)"""''')

P['g07'] = ('''# skipCaching's SOURCE disjunct dropped. PREDICTION: UNGATED — a union reaches the
# SOURCE side only through a value whose type is one, and under this port no
# identifier reference resolves and no conditional expression is checked. The
# branch histogram is the proof: 105 of 105 route-2 rows take branch 2.''',
'''old = """            if (source.flags & TypeFlagsUnion) <> 0
            {
                if (target.flags & TypeFlagsUnion) = 0
                {
                    let sl Checker.union_types_of(source)"""
new = """            if false
            {
                if (target.flags & TypeFlagsUnion) = 0
                {
                    let sl Checker.union_types_of(source)"""''')

P['g08'] = ('''# skipCaching's TARGET disjunct dropped. PREDICTION: the whole slice reverts to a
# recursion stop — route 2 becomes route 3 on every row — and the diagnostics go
# with it. The second half of g01, isolated to the ONE line that decides it.''',
'''old = """            if (target.flags & TypeFlagsUnion) <> 0
            {
                if (source.flags & TypeFlagsStructuredOrInstantiable) = 0
                {
                    let tl Checker.union_types_of(target)"""
new = """            if false
            {
                if (source.flags & TypeFlagsStructuredOrInstantiable) = 0
                {
                    let tl Checker.union_types_of(target)"""''')

P['g09'] = ('''# skipCaching's threshold moved from FOUR to TWO on the target side. PREDICTION:
# `number|bigint` and `number|string` have exactly two constituents, so a `< 2`
# test refuses every one of them and the arithmetic population goes to route 3.
# The row that says the constant is load-bearing and not decoration.''',
'''old = """                    let tl Checker.union_types_of(target)
                    if tl <> null
                    {
                        if (((tl as ref[Array[ref[Type]?]]).get_length()) as int) < 4
                            set skip_caching: true
                    }"""
new = """                    let tl Checker.union_types_of(target)
                    if tl <> null
                    {
                        if (((tl as ref[Array[ref[Type]?]]).get_length()) as int) < 2
                            set skip_caching: true
                    }"""''')

P['g10'] = ('''# skipCaching's threshold moved from FOUR to ONE HUNDRED on the target side.
# PREDICTION: the two route-3 rows — this battery's own five-constituent fixture —
# move to route 2 and ANSWER. The other half of g09, and together they are the
# price of the recursion measured from both sides.''',
'''old = """                    let tl Checker.union_types_of(target)
                    if tl <> null
                    {
                        if (((tl as ref[Array[ref[Type]?]]).get_length()) as int) < 4
                            set skip_caching: true
                    }"""
new = """                    let tl Checker.union_types_of(target)
                    if tl <> null
                    {
                        if (((tl as ref[Array[ref[Type]?]]).get_length()) as int) < 100
                            set skip_caching: true
                    }"""''')

P['g11'] = ('''# The two SOURCE-union arms of unionOrIntersectionRelatedTo swapped — the
# comparable relation gets eachType and the assignable one someType. PREDICTION:
# UNGATED, and it is g07's measurement from inside the function rather than from
# the fork. Transcribed for the slice that lands §3.11.''',
'''old = """            if relation = RelationComparable
            {
                set branch_out: 0
                return this.some_type_related_to_type(source, target, relation, en, intersection_state)
            }
            set branch_out: 1
            return this.each_type_related_to_type(source, target, relation, en, intersection_state)"""
new = """            if relation = RelationComparable
            {
                set branch_out: 1
                return this.each_type_related_to_type(source, target, relation, en, intersection_state)
            }
            set branch_out: 0
            return this.some_type_related_to_type(source, target, relation, en, intersection_state)"""''')

P['g12'] = ('''# The TARGET-union arm moved BELOW the target-intersection arm. PREDICTION:
# UNGATED — no type this checker can mint carries TypeFlagsIntersection, so the arm
# that now runs first never fires. ★The reference's own comment says the order is
# load-bearing (*"we need to deconstruct unions before intersections"*), and this
# row is what says the port cannot yet demonstrate it.''',
'''old = """        if (target.flags & TypeFlagsUnion) <> 0
        {
            set branch_out: 2
            var en: ref[AstNode]? error_node"""
new = """        if (target.flags & TypeFlagsIntersection) <> 0
        {
            set branch_out: 3
            this.record_unported("type-related-to-each-type", source.flags)
            return false
        }
        if (target.flags & TypeFlagsUnion) <> 0
        {
            set branch_out: 2
            var en: ref[AstNode]? error_node"""''')

P['g13'] = ('''# The two UNION-ORIGIN stops dropped — the port answers past the alias test it
# cannot make. PREDICTION: UNGATED — `origin` is set only by a union built out of
# another union or an intersection, and this port builds neither.''',
'''old = """                let so Checker.union_origin_of(source)
                if so <> null
                {
                    if (((so as ref[Type]).flags) & TypeFlagsIntersection) <> 0
                    {
                        set branch_out: 6
                        this.record_unported("union-origin-alias", target.flags)
                        return false
                    }
                }"""
new = """                let so Checker.union_origin_of(source)
                if so <> null
                {
                    if false
                    {
                        set branch_out: 6
                        this.record_unported("union-origin-alias", target.flags)
                        return false
                    }
                }"""''')

P['g14'] = ('''# getRegularTypeOfObjectLiteral's stop dropped. PREDICTION: UNGATED — the excess
# check one function up already stops on exactly the shape this guards (a FRESH
# object literal), and the only way past it is an intersection state this port
# cannot produce. The row is what makes that a measurement and not a reading.''',
'''old = """            if Checker.is_object_literal_type(source)
            {
                if (source.object_flags & ObjectFlagsFreshLiteral) <> 0
                {
                    this.record_unported("regular-type-of-object-literal", target.flags)
                    return false
                }
            }
            return this.type_related_to_some_type(source, target, relation, en, intersection_state)"""
new = """            return this.type_related_to_some_type(source, target, relation, en, intersection_state)"""''')

P['g15'] = ('''# typeRelatedToSomeType's `containsType(targetTypes, source)` early TRUE dropped.
# PREDICTION: the answers are unchanged — the loop below compares the source
# against every constituent and finds itself — so what moves is the fork's verdict
# only where the loop cannot get there, which is the elaboration tail.''',
'''old = """            if this.contains_type(target_types, source)
                return true
            var short_circuit false"""
new = """            var short_circuit false"""''')

P['g16'] = ('''# The PRIMITIVE-UNION short circuit dropped entirely. PREDICTION: the answers are
# the same and the row is a claim about that: the reference calls it a fast path,
# and the loop below reaches every constituent it consults. What it is NOT is a
# pure optimisation — the numeric-literal exclusion is g17.''',
'''old = """            if (target.object_flags & ObjectFlagsPrimitiveUnion) <> 0
                {
                    if (source.flags & TypeFlagsEnumLiteral) = 0"""
new = """            if false
                {
                    if (source.flags & TypeFlagsEnumLiteral) = 0"""''')

P['g17'] = ('''# The NUMERIC-LITERAL exclusion dropped — a NumberLiteral joins the short circuit
# for the assignable relation too. PREDICTION: the reference excludes it *"because
# numeric literals are assignable to numeric enum literals with the same value"*,
# and nothing in this port mints an enum literal, so this should be UNGATED with
# a reason that has an expiry date.''',
'''old = """                        if (source.flags & (TypeFlagsStringLiteral | TypeFlagsBooleanLiteral | TypeFlagsBigIntLiteral)) <> 0
                            set short_circuit: true"""
new = """                        if (source.flags & (TypeFlagsStringLiteral | TypeFlagsBooleanLiteral | TypeFlagsBigIntLiteral | TypeFlagsNumberLiteral)) <> 0
                            set short_circuit: true"""''')

P['g18'] = ('''# The ENUM-LITERAL exclusion dropped. PREDICTION: UNGATED, and the reason is
# already written down twice in this file — nothing in this port sets
# TypeFlagsEnum or TypeFlagsEnumLiteral on a type, which is what
# compute-enum-member-values' row says from the other side.''',
'''old = """                    if (source.flags & TypeFlagsEnumLiteral) = 0
                    {
                        if (source.flags & (TypeFlagsStringLiteral"""
new = """                    if 0 = 0
                    {
                        if (source.flags & (TypeFlagsStringLiteral"""''')

P['g19'] = ('''# The ALTERNATE-FORM test dropped from the short circuit. PREDICTION: the fresh
# and regular forms of a literal are two DIFFERENT types with the same value, and
# a target union built from an annotation holds the regular one while a source
# literal is fresh — so this is the test that answers `var x: "a"|"b" = "a"`.''',
'''old = """                if alternate <> null
                {
                    if this.contains_type(target_types, alternate)
                        return true
                }
                return false"""
new = """                return false"""''')

P['g20'] = ('''# The `primitive` switch's STRING arm dropped. PREDICTION: `var x: string|boolean
# = "a"` loses the base-primitive test and falls to the alternate form, which is a
# different type — so a true concatenation-shaped assignment answers FALSE and
# collects a TS2322 the reference does not have.''',
'''old = """                if (source.flags & TypeFlagsStringLiteral) <> 0
                    set primitive: this.string_type"""
new = """                if false
                    set primitive: this.string_type"""''')

P['g21'] = ('''# The discriminant map's three refutations dropped — every union target asks for
# the key property. PREDICTION: every route-2 comparison stops at
# get-matching-union-constituent, which is the whole slice again, and the row is
# what says the three cheap tests are not an optimisation but the containment.''',
'''old = """            var needs_key true
            if (target_types.get_length() as int) < 10
                set needs_key: false"""
new = """            var needs_key true
            if false
                set needs_key: false"""''')

P['g22'] = ('''# The discriminant map's `< 10` refutation raised to `< 2`. PREDICTION: a
# two-constituent union is no longer refuted by the length, so what saves it is the
# PRIMITIVE-UNION refutation alone — and this row separates the two tests that
# would otherwise read as one.''',
'''old = """            if (target_types.get_length() as int) < 10
                set needs_key: false"""
new = """            if (target_types.get_length() as int) < 2
                set needs_key: false"""''')

P['g23'] = ('''# getBestMatchingType's stop dropped — the elaboration tail says nothing.
# PREDICTION: the mark stops moving there, so report_error_results one level up is
# no longer silenced, and every union-target failure that reaches the tail gains
# the TS2322 the reference emits from a DIFFERENT constituent. The direction a
# SUBSEQUENCE relation can see.''',
'''old = """        if error_node <> null
            this.record_unported("get-best-matching-type", target.flags)
        false
    }"""
new = """        false
    }"""''')

P['g24'] = ('''# eachTypeRelatedToType's CORRESPONDENCE fast path dropped. PREDICTION: UNGATED —
# the function has no input at all (g07, g11), and this row is the third
# measurement of the same absence taken from inside the arm.''',
'''old = """            var matched false
            if stripped_types <> null"""
new = """            var matched false
            if false"""''')

P['g25'] = ('''# someTypeRelatedToType's `i == len-1` report narrowing dropped — every
# constituent may report. PREDICTION: UNGATED for the same reason as g24, and it is
# the one place in this slice where a wrong answer would be a FLOOD of diagnostics
# rather than one.''',
'''old = """            var en: ref[AstNode]? null
            if i = n - 1
                set en: error_node"""
new = """            var en: ref[AstNode]? error_node"""''')

P['g26'] = ('''# getUndefinedStrippedTargetIfNeeded replaced by the identity. PREDICTION: UNGATED
# — its first conjunct is a SOURCE union, which does not exist here. Transcribed
# whole because its four conjuncts are the containment that keeps
# extractTypesOfKind out of this slice.''',
'''old = """        let stripped this.get_undefined_stripped_target_if_needed(source, target)
        if stripped = null
            return false
        let stripped_target stripped as ref[Type]"""
new = """        let stripped_target target"""''')

P['g27'] = ('''# THE FORKPIN'S OWN NEGATIVE CONTROL — the verdict forced to 1 on every row.
# PREDICTION: forkgate RED on the verdict columns and the checksum, and NOTHING
# ELSE moves at all. An instrument that cannot be broken without moving something
# else is not measuring what its header claims.''',
'''old = """        var verdict 0
        if answer
            set verdict: 1
        if this.unported_mark() <> mark
            set verdict: 2
        let ev &ForkEvent^host(source.flags, target.flags, route, branch, verdict)"""
new = """        var verdict 1
        let ev &ForkEvent^host(source.flags, target.flags, route, branch, verdict)"""''')

P['g28'] = ('''# The FORKPIN's ROUTE column forced to 2. PREDICTION: forkgate RED on the route
# histogram and the checksum ONLY — the verdict columns are unchanged, because the
# route is a label on a decision and not the decision. The second half of g27's
# argument.''',
'''old = """        let ev &ForkEvent^host(source.flags, target.flags, route, branch, verdict)"""
new = """        let ev &ForkEvent^host(source.flags, target.flags, 2, branch, verdict)"""''')

P['g29'] = ('''# The fork's RESULT ignored — the branch always falls through to
# report_error_results. PREDICTION: diagcheck RED, and it is the largest invention
# in the battery: every assignment this slice newly answers TRUE would collect a
# TS2322. The row that says the `if result return true` line is the report seam
# and not a shortcut.''',
'''old = """            if this.record_fork(source, target, route, branch, fork_mark, result)
                return true"""
new = """            this.record_fork(source, target, route, branch, fork_mark, result)"""''')

P['g30'] = ('''# record_fork's MARK-based verdict replaced by the answer alone. PREDICTION: the
# COULD-NOT-ANSWER column goes to zero and nothing else moves — twelve rows that
# stopped inside the comparison start reading as honest FALSEs. The third state is
# what this whole chapter turns on and it has no other witness.''',
'''old = """        if this.unported_mark() <> mark
            set verdict: 2
        let ev &ForkEvent^host(source.flags, target.flags, route, branch, verdict)"""
new = """        let ev &ForkEvent^host(source.flags, target.flags, route, branch, verdict)"""''')

for k in sorted(P):
    doc, body = P[k]
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

control "g01 THE PREMISE (the whole structured branch) reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the excess-property guard forced FALSE" $CHECKER "$PATCHDIR/g02.py"
control "g03 the excess-property guard forced TRUE" $CHECKER "$PATCHDIR/g03.py"
control "g04 the common-property conjunction's TARGET test dropped" $CHECKER "$PATCHDIR/g04.py"
control "g05 the common-property conjunction's SOURCE test dropped" $CHECKER "$PATCHDIR/g05.py"
control "g06 the intersectionState conjunct dropped from the excess check" $CHECKER "$PATCHDIR/g06.py"
control "g07 skipCaching's SOURCE disjunct dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 skipCaching's TARGET disjunct dropped" $CHECKER "$PATCHDIR/g08.py"
control "g09 skipCaching's threshold moved from FOUR to TWO" $CHECKER "$PATCHDIR/g09.py"
control "g10 skipCaching's threshold moved from FOUR to ONE HUNDRED" $CHECKER "$PATCHDIR/g10.py"
control "g11 the two SOURCE-union arms swapped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the target-union arm moved BELOW the target-intersection arm" $CHECKER "$PATCHDIR/g12.py"
control "g13 the union-ORIGIN stops dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 getRegularTypeOfObjectLiteral's stop dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 typeRelatedToSomeType's containsType early TRUE dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 the PRIMITIVE-UNION short circuit dropped entirely" $CHECKER "$PATCHDIR/g16.py"
control "g17 the NUMERIC-LITERAL exclusion dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 the ENUM-LITERAL exclusion dropped" $CHECKER "$PATCHDIR/g18.py"
control "g19 the ALTERNATE-FORM test dropped" $CHECKER "$PATCHDIR/g19.py"
control "g20 the primitive switch's STRING arm dropped" $CHECKER "$PATCHDIR/g20.py"
control "g21 the discriminant map's three refutations dropped" $CHECKER "$PATCHDIR/g21.py"
control "g22 the discriminant map's < 10 refutation raised to < 2" $CHECKER "$PATCHDIR/g22.py"
control "g23 getBestMatchingType's stop dropped" $CHECKER "$PATCHDIR/g23.py"
control "g24 eachTypeRelatedToType's CORRESPONDENCE fast path dropped" $CHECKER "$PATCHDIR/g24.py"
control "g25 someTypeRelatedToType's last-constituent report narrowing dropped" $CHECKER "$PATCHDIR/g25.py"
control "g26 getUndefinedStrippedTargetIfNeeded replaced by the identity" $CHECKER "$PATCHDIR/g26.py"
control "g27 THE FORKPIN'S OWN NEGATIVE CONTROL (verdict forced to 1)" $CHECKER "$PATCHDIR/g27.py"
control "g28 the FORKPIN's ROUTE column forced to 2" $CHECKER "$PATCHDIR/g28.py"
control "g29 the fork's RESULT ignored (always falls through to the report)" $CHECKER "$PATCHDIR/g29.py"
control "g30 record_fork's MARK-based verdict replaced by the answer" $CHECKER "$PATCHDIR/g30.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
