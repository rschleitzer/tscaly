#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice105.sh — the slice-105 battery: THE TYPE ALIAS.
#
# ★★★ THE CHAPTER. `getTypeFromTypeAliasReference` was the second-largest row at
# stage 2 that is not the lib — 13 340 events over 966 units, 414 over 48 at stage
# 1 — and behind it sat `getDeclaredTypeOfTypeAlias`, the type-alias arm of
# `tryGetDeclaredTypeOfSymbol`, which no unit could reach because the reference
# door closed first. Both are ported; what stays a stop is the GENERIC path's
# instantiation, and its arity REPORT lands anyway.
#
# ★★★ THE SLICE'S PRODUCT AT STAGE 1 IS A TYPE, NOT A REPORT, AND THAT IS WHY IT
# BRINGS FOUR FIXTURES. Over the 1 541 units the corpus had before them, the whole
# chapter adds exactly ZERO diagnostics — every type alias out there is well
# formed — while the stop histogram loses 414 events on one row. A chapter whose
# product is an absence has to be given an input, or the battery measures the
# corpus's silence instead of the port's answer. So each fixture USES its alias in
# a position whose relation reports:
#
#   typealias_declared.ts   the alias ANSWERS — three TS2322 whose type came
#                           through the alias, one of them through a MERGED symbol
#                           whose first declaration is not the alias
#   typealias_circular.ts   TS2456 ×3 — the one-frame cycle and the two-frame one
#   typealias_arity.ts      TS2314 / TS2707 / TS2315, and one right-arity generic
#                           that reaches the instantiation stop
#   typealias_intrinsic.ts  the BuiltinIteratorReturn arm, made observable by an
#                           assignment because the printer stops one arm up
#
# ★ typeref_stops.ts is the fifth pin file and it is BORROWED: slice 95 wrote its
# `Al` row against this very wall, and it is the one input in the battery that
# predates the chapter.
#
# ★★★ TWO ROWS ARE PAIRS RATHER THAN CONTROLS, and both were added because their
# partner came out UNGATED for a reason no fixture could fix. g21 is g06 plus the
# TYPE-NODE memo, and it is what turns g06's silence into a statement about memo
# shadowing. g22 is the STAGE-2 defect this slice found in its own name resolution
# — a table lookup that STOPPED read as a MISS — and it is ungated at stage 1
# because its input is two units of 18 314.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice105.sh 2>&1 | tee /tmp/battery105.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice105.sh g08 g10` runs the baseline and
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

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Four of this slice's own and one
# borrowed — see the header.
PINFILES="
$FIX/typealias_declared.ts
$FIX/typealias_circular.ts
$FIX/typealias_arity.ts
$FIX/typealias_intrinsic.ts
$FIX/typeref_stops.ts
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

WORK=$(mktemp -d -t tscaly-ctl105)

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
    echo "  forkpin   unmoved — all five fixtures take the same routes and answer the same."
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


PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['g01'] = ('''# THE PREMISE — get_type_reference_type's TypeAlias arm reverted to the stop it
# carried through slice 104. PREDICTION: the whole chapter as the CORPUS sees it,
# and nothing else. Every route the corpus takes into a type alias comes through
# this door, so the stop histogram must go back to `get-type-from-type-alias-
# reference` at its old count and the four fixtures must all fall silent. What this
# row does NOT revert is the OTHER door — g02 is that one, and the difference
# between the two is the measurement.''',
"""old = '''        if (f & SymbolFlagsTypeAlias) <> 0
            return this.get_type_from_type_alias_reference(node, symbol)'''
new = '''        if (f & SymbolFlagsTypeAlias) <> 0
        {
            this.record_unported("get-type-from-type-alias-reference", 0)
            return null
        }'''""")

P['g02'] = ('''# The OTHER door — try_get_declared_type_of_symbol's TypeAlias arm reverted to its
# own slice-66 stop, with the reference door left open. PREDICTION: the same
# chapter closed from underneath, so the fixtures fall silent again but the tag
# they answer is `get-declared-type-of-type-alias` and not the reference one. ★If
# the two rows are indistinguishable, that says the second door has no caller of
# its own — which is what the stage-1 histogram said BEFORE this slice
# (`get-declared-type-of-type-alias` read zero events while the reference row read
# 414), and the row is here to check whether that is still true once the alias can
# be reached at all.''',
"""old = '''        if (f & SymbolFlagsTypeAlias) <> 0
            return this.get_declared_type_of_type_alias(symbol)'''
new = '''        if (f & SymbolFlagsTypeAlias) <> 0
        {
            this.record_unported("get-declared-type-of-type-alias", 0)
            return null
        }'''""")

P['g03'] = ('''# The PUSH dropped — push_type_resolution never consulted, so the body always
# proceeds. PREDICTION: `type A = A` has nothing to stop it and the recursion runs
# until the battery's own alarm kills the dumper. ★A killed call writes nothing, so
# BOTH the pin and the gate move, which is the honest verdict for a patch that
# makes the port not terminate — and it is the row that says the push is not an
# optimisation.''',
"""old = '''        if this.push_type_resolution(symbol, null, null, TypeSystemPropertyNameDeclaredType) = false
            return error_type'''
new = '''        if false
            return error_type'''""")

P['g04'] = ('''# The CIRCULAR REPORT dropped: the failed branch still answers errorType but says
# nothing. PREDICTION: diagcheck loses three TS2456 (a LOSS is a legal subsequence,
# so it stays green WITH A NUMBER) and the diagpin moves on typealias_circular.ts.
# This is the report half of g03's mechanism, separated from the termination half.''',
"""old = '''            this.error_on_node(error_node, DiagType_alias_0_circularly_references_itself)
            set t: error_type'''
new = '''            set t: error_type'''""")

P['g05'] = ('''# The circular report's ERROR NODE moved from the declaration's NAME to the
# declaration. PREDICTION: UNGATED, and the row is what turns a guess into a
# measurement. The obvious reading is a moved SPAN — same code, same count, three
# different ranges — but error() narrows a NAMED declaration to its name on its own
# way to a range, so the reference's two-line errorNode dance is a formality on
# every input that has a name, and a TypeAliasDeclaration always has one.''',
"""old = '''            var error_node AstNode.name_of(decl)
            if error_node = null
                set error_node: decl'''
new = '''            var error_node: ref[AstNode]? decl'''""")

P['g06'] = ('''# The MEMO never written — links.declared_type stays null. PREDICTION: every
# second reference re-enters the body, so an alias read twice reports twice. That
# is what `x2` is in typealias_circular.ts, and it had to be ADDED for this row to
# be able to fire: the report is made by getDeclaredTypeOfTypeAlias, so an alias
# referenced ONCE reports once with the memo and once without it. With a second
# reference the missing memo is a DUPLICATE TS2456, which diagcheck reads as an
# INVENTION and turns RED — the memo in this file is a correctness mechanism rather
# than a saving, and this is the row that says so.''',
"""old = '''        if links.declared_type = null
            set links.declared_type: t
        links.declared_type'''
new = '''        t'''""")

P['g07'] = ('''# The memo written UNCONDITIONALLY — the reference's `if links.declaredType == nil`
# guard dropped. PREDICTION: it is a claim about the RECURSIVE call. The body can
# reach the same symbol through its own annotation and fill the row on the way in;
# overwriting it on the way out replaces the answer the inner frame settled on. ★If
# nothing moves, the row says no fixture here has that shape, and it says so with a
# number instead of a sentence.''',
"""old = '''        if links.declared_type = null
            set links.declared_type: t'''
new = '''        set links.declared_type: t'''""")

P['g08'] = ('''# `core.Find` replaced by declaration ZERO. PREDICTION: typealias_declared.ts's
# `Merged` reads a ModuleDeclaration, whose Type() is nil, so the
# `declared-type-of-type-alias-no-type` stop fires and the third TS2322 is lost.
# The row is what makes Find a MECHANISM rather than an index, and the fixture was
# written for it.''',
"""old = '''                if declaration = null
                {
                    let k AstNode.kind_of(d as ref[AstNode])
                    if k = KindTypeAliasDeclaration
                        set declaration: d
                    if k = KindJSTypeAliasDeclaration
                        set declaration: d
                }'''
new = '''                if declaration = null
                    set declaration: d'''""")

P['g09'] = ('''# links.type_parameters never stored. PREDICTION: getTypeFromTypeAliasReference's
# fork is never taken, so a GENERIC alias falls straight through to
# checkNoTypeArguments — the two arity reports disappear, TS2315 appears where
# TS2314 belonged, and `get-type-alias-instantiation` leaves the stop log. ★Both
# directions at once, which is why diagcheck should go RED rather than merely
# shrink.''',
"""old = '''                    set links.type_parameters: type_parameters'''
new = '''                    set links.type_parameters: links.type_parameters'''""")

P['g10'] = ('''# The arity comparison's LOWER bound dropped — `numTypeArguments < minTypeArgument
# Count` no longer counts. PREDICTION: TS2314 and TS2707 both go, because both of
# this fixture's failures are too FEW arguments; the upper bound is a different
# input and g11 is its row.''',
"""old = '''            if num_type_arguments < min_count
                set out_of_range: true'''
new = '''            if false
                set out_of_range: true'''""")

P['g11'] = ('''# The arity comparison's UPPER bound dropped. PREDICTION: one TS2314 lost, on
# typealias_arity.ts's `d`. ★It is the row that made the fixture grow: with only
# too-FEW arguments in it this control moved nothing at all, and a comparison with
# two sides needs an input on each side or one of its halves is untested rather
# than proven.''',
"""old = '''            if num_type_arguments > tp_count
                set out_of_range: true'''
new = '''            if false
                set out_of_range: true'''""")

P['g12'] = ('''# get_min_type_argument_count forced to the full parameter count, so
# report_type_argument_arity's `min_count < tp_count` fork always chooses TS2314.
# PREDICTION: diagpin RED with the CODE changed and the count unchanged — TS2707
# becomes TS2314 on `H`, and the defaulted parameter stops being visible at all.''',
"""old = '''            let min_count this.get_min_type_argument_count(links.type_parameters as ref[Array[ref[Type]?]])'''
new = '''            let min_count tp_count'''""")

P['g13'] = ('''# checkNoTypeArguments' RESULT ignored — the alias is returned whatever it says.
# PREDICTION: the call still REPORTS (it is the call that emits TS2315), so
# diagcheck does not move by one diagnostic and only the returned TYPE changes:
# errorType becomes the alias's own type. ★It is the row that separates the report
# from the answer, and if nothing at all moves it says no reader downstream can yet
# tell errorType from `number`.''',
"""old = '''        if this.check_no_type_arguments(node, symbol)
            return t
        error_type'''
new = '''        this.check_no_type_arguments(node, symbol)
        t'''""")

P['g14'] = ('''# The BuiltinIteratorReturn arm dropped: the alias keeps the intrinsic marker.
# PREDICTION: the marker is TypeFlagsAny, which is assignable to `number`, so
# typealias_intrinsic.ts loses its TS2322 — a LOSS, so diagcheck stays green with a
# number — and the RELPIN moves on the source flag word, 4 (Undefined) back to 1
# (Any). ★The relpin is the instrument here because the printer cannot reach either
# type: the dump walk stops one arm up.''',
"""old = '''                if Checker.name_bytes_are(Slice[char](nl as size_t, nd), "BuiltinIteratorReturn")
                    set t: this.builtin_iterator_return_type()'''
new = '''                if false
                    set t: this.builtin_iterator_return_type()'''""")

P['g15'] = ('''# The NAME test forced true — every `= intrinsic` alias becomes the builtin
# iterator return. PREDICTION: the opposite direction from g14 and the one a
# subsequence catches: `Other` turns into `undefined` and INVENTS a second TS2322,
# so diagcheck goes RED. A predicate with two failure directions needs both rows.''',
"""old = '''                if Checker.name_bytes_are(Slice[char](nl as size_t, nd), "BuiltinIteratorReturn")
                    set t: this.builtin_iterator_return_type()'''
new = '''                set t: this.builtin_iterator_return_type()'''""")

P['g16'] = ('''# strict_builtin_iterator_return answers FALSE, so the arm hands back `any`.
# PREDICTION: g14 on every column, because `any` and the intrinsic marker carry the
# same flag word — which is the honest reason this option is written as a reading
# rather than as an arm, and the row is what turns that sentence into a
# measurement.''',
"""old = '''    function strict_builtin_iterator_return() returns bool
        true'''
new = '''    function strict_builtin_iterator_return() returns bool
        false'''""")

P['g17'] = ('''# THE MARK dropped in get_type_from_type_alias_reference. PREDICTION: an
# UNPORTED becomes an errorType, because get_declared_type_of_symbol answers the
# same thing for *the reference answers nothing* and for *this port could not get
# there*. The corpus is where this shows: an alias whose own annotation stops now
# hands back a type, and every reader downstream believes it. ★If diagcheck goes
# RED the invention is caught; if only the stopgate moves, the row prices what the
# mark is worth today rather than what it protects against.''',
"""old = '''        let mark this.unported_mark()
        let t this.get_declared_type_of_symbol(symbol)
        if this.unported_mark() <> mark
            return null'''
new = '''        let t this.get_declared_type_of_symbol(symbol)'''""")

P['g18'] = ('''# The DeclaredType arm of type_resolution_has_property reverted to the tail's
# stop. PREDICTION: the cycle search's FIRST test is *has this frame been answered*,
# so with the arm reporting, every alias resolved while another one is on the stack
# records a stop — and `type B = C; type C = B` is exactly that shape. The arm is
# minted by this slice and this is the row that says why.''',
"""old = '''        if r.property_name = TypeSystemPropertyNameDeclaredType
        {
            if r.target_symbol = null
                return false
            let al this.type_alias_link_of(r.target_symbol as ref[Symbol])
            return al.declared_type <> null
        }'''
new = '''        if r.property_name = TypeSystemPropertyNameDeclaredType
        {
            this.record_unported("type-resolution-has-property", r.property_name)
            return false
        }'''""")

P['g19'] = ('''# The POP taken on the no-type stop as well. PREDICTION: UNGATED, and for a reason
# that PAIRS IT WITH g08 rather than excusing it — that stop stands on the
# assertion route (a TypeAlias symbol whose chosen declaration has no type node),
# and the only thing in this battery that can reach it is g08. A row whose input
# exists only under another row is worth stating as such: on the unpatched tree it
# proves the route is unreachable, which is exactly what the stop is there to say.''',
"""old = '''        if type_node = null
        {
            this.record_unported("declared-type-of-type-alias-no-type", AstNode.kind_of(decl))
            return null
        }'''
new = '''        if type_node = null
        {
            this.record_unported("declared-type-of-type-alias-no-type", AstNode.kind_of(decl))
            let unused this.pop_type_resolution()
            return null
        }'''""")

P['g20'] = ('''# The declared type asked through try_get_declared_type_of_symbol instead of
# get_declared_type_of_symbol, i.e. WITHOUT the errorType fallback. PREDICTION:
# UNGATED, and it is the row that dates the mark above it: the two differ only when
# the inner answer is nil, which after the mark can only mean a stop this function
# already returns on. If it moves, the fallback is doing work the mark was credited
# with.''',
"""old = '''        let t this.get_declared_type_of_symbol(symbol)
        if this.unported_mark() <> mark
            return null'''
new = '''        let t this.try_get_declared_type_of_symbol(symbol)
        if this.unported_mark() <> mark
            return null
        if t = null
            return null'''""")

P['g21'] = ('''# g06 AND the TYPE-NODE memo one level down, together. PREDICTION: the duplicate
# TS2456 that g06 was written for, and therefore diagcheck RED. ★It is the row that
# turns g06's UNGATED into a MECHANISM rather than a missing input: without the
# declared-type memo the body does run a second time, but its first statement is
# `get_type_from_type_node(<the alias's own annotation>)` — one node, already
# memoised, so the re-entry that would fail the push never happens and the frame
# comes out RESOLVED. One memo is shadowed by the other, and only the pair says so.''',
"""old = '''        if links.declared_type = null
            set links.declared_type: t
        links.declared_type'''
new = '''        t'''
old2 = '''        let links this.type_node_link_of(node)
        if links.resolved_type <> null
            return links.resolved_type
        if this.is_const_type_reference(node)'''
new2 = '''        let links this.type_node_link_of(node)
        if this.is_const_type_reference(node)'''""")

P['g22'] = ('''# THE STAGE-2 DEFECT — lookup_in_table's MARK dropped, so a table lookup that
# STOPPED reads as a MISS again and resolve_name walks one table further out.
# PREDICTION: UNGATED AT STAGE 1, and the row says which corpus it belongs to
# rather than pretending otherwise. Its input is `import {E} from "./f1"; export
# type E = E;` — one local symbol flagged ALIAS carrying both declarations, plus an
# EXPORT symbol flagged TypeAlias — and there are exactly TWO such units in 18 314,
# both at stage 2. With the mark gone this slice's chapter resolves the export
# against itself and INVENTS a TS2456 where the reference reports only the missing
# module. ★What the row DOES show at stage 1 is the price: the stop histogram
# should move, because a walk that ends earlier reaches fewer stops.''',
"""old = '''        let mark this.unported_mark()
        let found this.lookup_symbol(symbols, name_data, name_len, meaning)
        if this.unported_mark() <> mark
            set stopped: true
        found'''
new = '''        this.lookup_symbol(symbols, name_data, name_len, meaning)'''""")

for name, (why, body) in list(P.items()):
    open(os.path.join(D, name + '.py'), 'w').write(
        "import sys\n" + why + "\n" + body +
        "\npath = sys.argv[1]\ns = open(path).read()\n"
        "assert old in s, 'anchor moved: ' + repr(old[:60])\n"
        "s = s.replace(old, new)\n"
        "try:\n    old2\nexcept NameError:\n    pass\nelse:\n"
        "    assert old2 in s, 'anchor 2 moved'\n    s = s.replace(old2, new2)\n"
        "open(path, 'w').write(s)\n")
MKPATCHES

baseline

control "g01 THE PREMISE — the reference door reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the OTHER door — try_get_declared_type_of_symbol's arm reverted" $CHECKER "$PATCHDIR/g02.py"
control "g03 the PUSH dropped (no cycle detection)" $CHECKER "$PATCHDIR/g03.py"
control "g04 the CIRCULAR REPORT dropped" $CHECKER "$PATCHDIR/g04.py"
control "g05 the circular report's error node is the DECLARATION, not its name" $CHECKER "$PATCHDIR/g05.py"
control "g06 the MEMO never written" $CHECKER "$PATCHDIR/g06.py"
control "g07 the memo written UNCONDITIONALLY" $CHECKER "$PATCHDIR/g07.py"
control "g08 core.Find replaced by declaration ZERO" $CHECKER "$PATCHDIR/g08.py"
control "g09 links.type_parameters never stored" $CHECKER "$PATCHDIR/g09.py"
control "g10 the arity comparison's LOWER bound dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the arity comparison's UPPER bound dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 get_min_type_argument_count forced to the full count" $CHECKER "$PATCHDIR/g12.py"
control "g13 checkNoTypeArguments' RESULT ignored" $CHECKER "$PATCHDIR/g13.py"
control "g14 the BuiltinIteratorReturn arm dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 the BuiltinIteratorReturn NAME test forced TRUE" $CHECKER "$PATCHDIR/g15.py"
control "g16 strict_builtin_iterator_return answers FALSE" $CHECKER "$PATCHDIR/g16.py"
control "g17 THE MARK dropped in get_type_from_type_alias_reference" $CHECKER "$PATCHDIR/g17.py"
control "g18 the DeclaredType arm of type_resolution_has_property reverted" $CHECKER "$PATCHDIR/g18.py"
control "g19 the POP taken on the no-type stop as well" $CHECKER "$PATCHDIR/g19.py"
control "g20 the declared type asked WITHOUT the errorType fallback" $CHECKER "$PATCHDIR/g20.py"
control "g21 g06 AND the type-node memo, together" $CHECKER "$PATCHDIR/g21.py"
control "g22 lookup_in_table's MARK dropped (the stage-2 defect)" $CHECKER "$PATCHDIR/g22.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
