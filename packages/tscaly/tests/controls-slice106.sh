#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice106.sh — the slice-106 battery: THE TYPE PARAMETER'S DEFERRED CHECK.
#
# ★★★ THE CHAPTER. `checkTypeParameterDeferred` was the largest row by UNIT at
# stage 2 that is neither the lib nor a name resolution — `get-declared-type-of-
# type-parameter 169` at 1 697 units, 245 events over 86 units at stage 1 — and
# what stood at that line was ONE unconditional report standing in for the
# variance machinery behind the function's second `if`. The function is ported
# whole; `getTypeParameterModifiers` is the code, and its answer is ZERO for every
# type parameter either corpus contains that carries no `in`/`out`.
#
# ★★★ THE PRODUCT IS TWO THINGS AND THEY ARE NOT THE SAME SIZE. The row closes for
# 86 stage-1 units, none of which gains a diagnostic — and FOUR TS2637 arrive, three
# of them in a fixture that has been in this corpus since the parser slices and one
# in a fixture this slice brings. The reference reports exactly those four and the
# unit that carries three of them is now EXACT rather than a subsequence.
#
# ★★★ ONE ROW COST A FIXTURE AND THE FIXTURE IS THE FINDING. g03 removes the fold
# over a symbol's declarations, and its first draft came back UNGATED — not for
# want of an input but because the corpus's only merged type parameter carries its
# modifiers on declaration ZERO and carries `in out`, which is invariance and has
# no arm. §3.5v calls that `uncovered` and its answer is to write the fixture:
# `variance_merged.ts`, where the modifier is on the SECOND declaration.
#
# ★★★ THE MARKER ARM IS A WALL AND THE BATTERY HAS TO SAY SO WITH A NUMBER. Its
# product is two marker type references handed to checkTypeAssignableTo, and the
# relation cannot answer about two references to ONE generic target — probed
# directly: `interface I<T> { x: T }` with `I<string> = I<number>` stops at
# `common-property-check`. So g15 prices the wall by removing the report, and the
# rows around it are what say the arm is REACHED rather than guarded away.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice106.sh 2>&1 | tee /tmp/battery106.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice106.sh g05 g08` runs the baseline and
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

# ★ ONE MECHANISM PER FILE (slice 72's rule). Three of this slice's own and THREE
# borrowed, which is the most any battery here has borrowed and is what the
# chapter's shape gives it: `parser_types_generic.ts` has carried this slice's
# three TS2637 since the parser dimension without anything able to report them,
# and slice 60 wrote `checker_type_parameter_deferred_variance.ts` for a deferred
# arm whose own header then said it does not execute. Both are inputs this slice
# found rather than made.
PINFILES="
$FIX/parser_types_generic.ts
$FIX/variance_alias.ts
$FIX/variance_class.ts
$FIX/variance_merged.ts
$FIX/checker_type_parameter_deferred_variance.ts
$FIX/checker_type_parameter_duplicate.ts
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

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['g01'] = ('''# THE PREMISE — the whole chapter reverted to the unconditional report it carried
# through slice 105, right under the guard. PREDICTION: this slice as the CORPUS
# sees it, and nothing else. The four TS2637 go, `get-declared-type-of-type-
# parameter 169` comes back at its old count, and the stop log grows rather than
# shrinks — which is the half of the verdict g02 is here to separate.''',
"""old = '''        if owes = false
            return
        ; `typeParameter := c.getDeclaredTypeOfTypeParameter(c.getSymbolOfDeclaration(node))`'''
new = '''        if owes = false
            return
        this.record_unported("get-declared-type-of-type-parameter", KindTypeParameter)
        if true
            return
        ; `typeParameter := c.getDeclaredTypeOfTypeParameter(c.getSymbolOfDeclaration(node))`'''""")

P['g02'] = ('''# THE OTHER ZERO — get_type_parameter_modifiers answers ModifierFlagsNone for
# everything, so every owed parameter falls out at `modifiers = 0`. PREDICTION:
# the same four TS2637 lost as g01 and the same silence — but the stop log moves
# the OPPOSITE way, DOWN by the marker rows rather than up by 245 events. ★The two
# rows together are what say which of the chapter's two zeros the product is: g01
# removes the answer, g02 removes the question, and only the stop count tells
# them apart.''',
"""old = '''        flags & (ModifierFlagsIn | ModifierFlagsOut | ModifierFlagsConst)'''
new = '''        ModifierFlagsNone'''""")

P['g03'] = ('''# The modifier FOLD replaced by declaration ZERO. PREDICTION: the two TS2637 of
# variance_merged.ts go — a LOSS, so diagcheck stays GREEN WITH A NUMBER and the
# diagpin is what says it. ★★★THE ROW EXISTS IN THIS SHAPE BECAUSE THE FIRST DRAFT
# WAS UNGATED AND THE CORPUS'S OWN MERGED PARAMETER COULD NOT FIX IT.
# `checker_type_parameter_duplicate.ts` really does carry a symbol with two
# declarations (the symbol dump reads two `d 1 169` lines), and it gates nothing
# twice over: its modifiers sit on declaration ZERO, and `in out` is invariance,
# whose arm is a return. ★★§3.5v's first row is `uncovered` and its answer is *write
# the fixture*, not *file it under one of the four* — `type L<M, in M> = M` is
# that fixture, and it also shows the fold reaching BOTH declarations: the
# parameter written WITHOUT a modifier reports too, because the symbol is one.''',
"""old = '''            let n Symbol.declaration_count(s)
            var i 0
            while i < n
            {
                set flags: flags | b.modifier_flags(Symbol.declaration_at(s, i))
                set i: i + 1
            }'''
new = '''            set flags: flags | b.modifier_flags(Symbol.declaration_at(s, 0))'''""")

P['g04'] = ('''# The INNER mask drops Const. PREDICTION: UNGATED, and it is the row that proves
# Const is computed and thrown away here rather than read. The caller masks with
# In|Out, so a `const` type parameter cannot reach any arm either way — which is
# what makes the wider mask the reference's shape and not this port's need. ★It
# pairs with g05, which removes the OTHER mask.''',
"""old = '''        flags & (ModifierFlagsIn | ModifierFlagsOut | ModifierFlagsConst)'''
new = '''        flags & (ModifierFlagsIn | ModifierFlagsOut)'''""")

P['g05'] = ('''# The CALLER's mask dropped, so `const` counts as a variance annotation.
# PREDICTION: diagcheck RED. `type I<const T> = T` sits in parser_types_generic.ts
# four lines under the three that report, and with this mask gone it takes the
# alias arm and INVENTS a fifth TS2637 the reference does not have. ★This is the
# row that says the second mask is a mechanism where g04 says the first is not —
# one condition, two masks, and only one of them decides anything.''',
"""old = '''        let modifiers this.get_type_parameter_modifiers(tp as ref[Type]) & (ModifierFlagsIn | ModifierFlagsOut)'''
new = '''        let modifiers this.get_type_parameter_modifiers(tp as ref[Type])'''""")

P['g06'] = ('''# The objectFlags test forced TRUE — every alias counts as a non-object one.
# PREDICTION: diagcheck RED on variance_alias.ts, which is the file written for
# this row: `Fn` and `Obj` have declared types this port CAN build and that carry
# ObjectFlagsAnonymous, so forcing the test invents a TS2637 on each. `Mapped` is
# not among them — the mark withholds it — which is g08's half.''',
"""old = '''            if (d.object_flags & (ObjectFlagsAnonymous | ObjectFlagsMapped)) = 0
                set alias_of_non_object: true'''
new = '''            set alias_of_non_object: true'''""")

P['g07'] = ('''# The objectFlags test forced FALSE — no alias ever counts as a non-object one.
# PREDICTION: all four TS2637 go and the marker arm takes their place. A LOSS is a
# legal subsequence, so diagcheck stays GREEN WITH A NUMBER and only the diagpin
# and the count say what happened. ★It is g06's opposite direction, and a
# predicate with two failure directions needs both rows (slice 105's finding six).''',
"""old = '''            if (d.object_flags & (ObjectFlagsAnonymous | ObjectFlagsMapped)) = 0
                set alias_of_non_object: true'''
new = '''            if false
                set alias_of_non_object: true'''""")

P['g08'] = ('''# THE MARK dropped in the alias arm. PREDICTION: diagcheck RED 1 — `Mapped<in T>`
# in variance_alias.ts is an alias whose declared type this port STOPS on, and an
# errorType carries objectFlags 0 exactly like a non-object one does, so without
# the mark it INVENTS a TS2637 the reference does not have. ★★The row is what
# separates the two reasons a silent alias is silent: with the mark, `Mapped` is
# withheld; without it, it is answered wrongly. Nothing in the C section can tell
# those apart from one side alone.''',
"""old = '''            let mark this.unported_mark()
            let declared this.get_declared_type_of_symbol(sym as ref[Symbol])
            if this.unported_mark() <> mark
                return'''
new = '''            let declared this.get_declared_type_of_symbol(sym as ref[Symbol])'''""")

P['g09'] = ('''# The alias-parent test in the ARM forced TRUE, so a class and an interface take
# the alias route too. PREDICTION: diagcheck RED — variance_class.ts and
# checker_type_parameter_deferred_variance.ts invent a TS2637 on every annotated
# parameter, because getDeclaredTypeOfClassOrInterface answers an Interface type
# and an Interface type is neither Anonymous nor Mapped. ★It is the row that says
# the arm's first term is a test on the PARENT and not a spelling of `modifiers
# != 0`.''',
"""old = '''        var alias_of_non_object false
        if alias_parent
        {
            let mark this.unported_mark()'''
new = '''        var alias_of_non_object false
        if true
        {
            let mark this.unported_mark()'''""")

P['g10'] = ('''# The `modifiers = 0` early return dropped. PREDICTION: the loudest row in the
# battery — every type parameter of every alias in the corpus reaches the alias
# arm, and every alias whose declared type is not an object type invents a TS2637.
# ★It is the row that says this slice's product IS that early return: the chapter
# is a guard whose body no corpus unit enters, and removing the guard turns a
# no-op into a hundred inventions.''',
"""old = '''        let modifiers this.get_type_parameter_modifiers(tp as ref[Type]) & (ModifierFlagsIn | ModifierFlagsOut)
        if modifiers = 0
            return'''
new = '''        let modifiers this.get_type_parameter_modifiers(tp as ref[Type]) & (ModifierFlagsIn | ModifierFlagsOut)
        if false
            return'''""")

P['g11'] = ('''# The INVARIANT test replaced by `modifiers <> 0`, which is the reading a reader
# reaches for. PREDICTION: UNGATED ON DIAGCHECK AND RED ON THE STOP LOG. `in out`
# is invariance and the reference makes no comparison for it at all; under this
# patch `class D<in out T>` in variance_class.ts and `interface I<in out U, U>` in
# checker_type_parameter_duplicate.ts each record a `create-marker-type` the
# reference never asks for. ★★It costs no diagnostic in either direction, which is
# exactly why the row exists — a wrong reading here is invisible to every
# instrument but the stop log.''',
"""old = '''        var single false
        if modifiers = ModifierFlagsIn
            set single: true
        if modifiers = ModifierFlagsOut
            set single: true
        if single = false
            return'''
new = '''        var single false
        if modifiers <> 0
            set single: true
        if single = false
            return'''""")

P['g12'] = ('''# The guard's INTERFACE arm dropped. PREDICTION: the three interfaces in the pin
# files stop reaching the chapter, so the stop log loses their marker rows and
# diagcheck moves nothing — an interface's parameter has no report in this slice.
# ★The row prices the arm in units rather than in diagnostics, which for two of
# the guard's three parents is the only currency there is.''',
"""old = '''        if Checker.kind_or_unknown(parent) = KindInterfaceDeclaration
            set owes: true
        if Parser.is_class_like_node(parent)'''
new = '''        if false
            set owes: true
        if Parser.is_class_like_node(parent)'''""")

P['g13'] = ('''# The guard's CLASS-LIKE arm dropped. PREDICTION: the same shape as g12 with a
# different count — variance_class.ts's three classes leave the log and nothing
# else moves. ★The two rows exist separately because a guard with three terms and
# one shared verdict is where a term goes missing without anything noticing.''',
"""old = '''        if Parser.is_class_like_node(parent)
            set owes: true
        if alias_parent
            set owes: true'''
new = '''        if false
            set owes: true
        if alias_parent
            set owes: true'''""")

P['g14'] = ('''# The guard's ALIAS arm dropped. PREDICTION: all four TS2637 go — this is the
# only one of the three parents that carries a report — so diagcheck stays GREEN
# WITH A NUMBER and the diagpin moves on two files. ★Read against g12 and g13 it
# is the row that says where the slice's diagnostics come from: one parent kind of
# three, and the other two are unit counts.''',
"""old = '''        if alias_parent
            set owes: true
        if owes = false'''
new = '''        if false
            set owes: true
        if owes = false'''""")

P['g15'] = ('''# THE WALL'S REPORT dropped — the marker arm returns silently. PREDICTION:
# UNGATED ON DIAGCHECK, because the arm produces no diagnostic either way, and RED
# on the stop log with a NUMBER: the count it removes is exactly how many marker
# comparisons this corpus asks for. ★★A wall that reports nothing is a port
# claiming to answer, which is §3.5ao's shape and the reason the row is here at
# all rather than the reason it is expected to be loud.''',
"""old = '''        this.record_unported("create-marker-type", modifiers)'''
new = '''        if false
            this.record_unported("create-marker-type", modifiers)'''""")

P['g16'] = ('''# The modifiers read from the DECLARATION's symbol directly, skipping the hop
# through the declared type. PREDICTION: UNGATED — `new_type_parameter(symbol)`
# stores exactly the symbol this port already has in hand, so the hop is a
# formality on every input the corpus contains. ★It is slice 105's finding five in
# a second chapter: a transcription that moves nothing is still a claim about
# inputs this corpus does not have, and the row is what turns the claim into a
# number. ★If it MOVES, the memo in get_declared_type_of_type_parameter is handing
# back a type minted for a different symbol, which would be a defect and not a
# simplification.''',
"""old = '''        let modifiers this.get_type_parameter_modifiers(tp as ref[Type]) & (ModifierFlagsIn | ModifierFlagsOut)'''
new = '''        let probe this.new_type_parameter(tp_symbol)
        let modifiers this.get_type_parameter_modifiers(probe) & (ModifierFlagsIn | ModifierFlagsOut)'''""")

for name, (why, body) in list(P.items()):
    open(os.path.join(D, name + '.py'), 'w').write(
        "import sys\n" + why + "\n" + body +
        "\npath = sys.argv[1]\ns = open(path).read()\n"
        "assert old in s, 'anchor moved: ' + repr(old[:60])\n"
        "assert s.count(old) == 1, 'anchor is not unique: ' + repr(old[:60])\n"
        "s = s.replace(old, new)\n"
        "try:\n    old2\nexcept NameError:\n    pass\nelse:\n"
        "    assert old2 in s, 'anchor 2 moved'\n    s = s.replace(old2, new2)\n"
        "open(path, 'w').write(s)\n")
MKPATCHES

baseline

control "g01 THE PREMISE — the whole chapter reverted to its report" $CHECKER "$PATCHDIR/g01.py"
control "g02 the OTHER zero — get_type_parameter_modifiers answers None" $CHECKER "$PATCHDIR/g02.py"
control "g03 the modifier FOLD replaced by declaration ZERO" $CHECKER "$PATCHDIR/g03.py"
control "g04 the INNER mask drops Const" $CHECKER "$PATCHDIR/g04.py"
control "g05 the CALLER's mask dropped — const counts as variance" $CHECKER "$PATCHDIR/g05.py"
control "g06 the objectFlags test forced TRUE" $CHECKER "$PATCHDIR/g06.py"
control "g07 the objectFlags test forced FALSE" $CHECKER "$PATCHDIR/g07.py"
control "g08 THE MARK dropped in the alias arm" $CHECKER "$PATCHDIR/g08.py"
control "g09 the arm's alias-parent test forced TRUE" $CHECKER "$PATCHDIR/g09.py"
control "g10 the modifiers = 0 early return dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the INVARIANT test read as modifiers <> 0" $CHECKER "$PATCHDIR/g11.py"
control "g12 the guard's INTERFACE arm dropped" $CHECKER "$PATCHDIR/g12.py"
control "g13 the guard's CLASS-LIKE arm dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 the guard's ALIAS arm dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 THE WALL'S REPORT dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 the modifiers read from the declaration's symbol" $CHECKER "$PATCHDIR/g16.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
