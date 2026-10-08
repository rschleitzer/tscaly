#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice107.sh — the slice-107 battery: THE USE BEFORE THE DECLARATION.
#
# ★★★ THE CHAPTER. `isBlockScopedNameDeclaredBeforeUse` was the largest row at
# stage 2 that is neither the lib nor a name resolution — 1 401 + 1 361 units under
# two tags, 10 396 events on the second alone — and what stood at its three call
# sites was a stop. The function is ported whole, together with
# isUsedInFunctionOrInstanceProperty, isSameScopeDescendentOf,
# isImmediatelyUsedInInitializerOfBlockScopedVariable,
# isPropertyImmediatelyReferencedWithinDeclaration, isPropertyInitializedInStaticBlocks
# and ast.GetEnclosingBlockScopeContainer, and both consumers —
# checkResolvedBlockScopedVariable and checkPropertyNotUsedBeforeDeclaration — are
# finished behind it.
#
# ★★★ ITS PRODUCT IS FIVE NEGATIVE REPORTS, AND ALL FIVE FIRE WHEN THE FUNCTION
# ANSWERS FALSE: TS2448, TS2449, TS2450, TS2729 and TS2449 again. So a port that
# answered `true` everywhere would be SILENT and pass every subsequence gate, and
# a port that answered `false` everywhere would invent on every block-scoped name
# in the corpus. Half the rows below are one of those two ports.
#
# ★★★ THE CORPUS COULD NOT MEASURE THIS CHAPTER AND THE MEASUREMENT SAYS WHY.
# Five reference diagnostics of the four codes exist over the whole stage-1 corpus,
# across five units — and THREE of them sit behind stops in four OTHER chapters
# (get-type-for-binding-element-parent, get-type-from-type-node,
# check-return-expression), so the chapter can reach two. Four fixtures carry the
# rest, and the pins below are those four plus the two corpus units that DO reach.
#
# ★★★ TWO ARMS HAVE NO INPUT AT ALL AND THE BATTERY SAYS SO WITH A ROW EACH. The
# BINDING-ELEMENT arm and the CLASS-LIKE arm are written from the reference and
# every shape that reaches them at stage 1 stops in another chapter first
# (get-type-for-binding-element-parent, check-decorators, get-late-bound-symbol).
# g22 and g23 remove them and predict UNGATED — §3.5v's `uncovered`, filed with the
# stop that covers it rather than left as a silence.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice107.sh 2>&1 | tee /tmp/battery107.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice107.sh g05 g08` runs the baseline and
# then only the named rows. ★The baseline is NEVER skipped: every verdict below is a
# comparison against it.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
AST=$PKG/0.1.1/tscaly/ast.scaly
FIX=$PKG/tests/fixtures
CASES=$PKG/tests/out/cases

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule) — four of this slice's own, and TWO
# BORROWED FROM THE CORPUS ITSELF. `fixtures_binder_expando_hoisted` and
# `fixtures_parser_jsx_unary`'s second unit have each carried a TS2448 the
# reference reports since the binder and parser dimensions, with nothing on this
# side able to produce it; both became EXACT the moment this chapter landed, and
# they are pinned here because a fixture is written around the arm its author is
# thinking of and these two were not.
PINFILES="
$FIX/blockscope_before_use.ts
$FIX/blockscope_own_initializer.ts
$FIX/blockscope_property_initializer.ts
$FIX/blockscope_static_block.ts
$FIX/blockscope_deferred_field.ts
$CASES/fixtures_binder_expando_hoisted/units/u00_binder_expando_hoisted.ts
$CASES/fixtures_parser_jsx_unary/units/u01_guard.tsx
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

WORK=$(mktemp -d -t tscaly-ctl107)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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
    echo "  diagpin   unmoved — all seven pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all seven pin files answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all seven pin files log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.rel" "$WORK/ctl.rel"; then
    echo "  relpin    unmoved — all seven pin files make the same comparisons, in order."
  else
    green "relpin    RED"
    diff "$WORK/base.rel" "$WORK/ctl.rel" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.kind" "$WORK/ctl.kind"; then
    echo "  kindpin   unmoved — all seven pin files ask the same kinds and take the same arms."
  else
    green "kindpin   RED"
    diff "$WORK/base.kind" "$WORK/ctl.kind" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.fn" "$WORK/ctl.fn"; then
    echo "  fnpin     unmoved — all seven pin files decide the same way, in the same order."
  else
    green "fnpin     RED"
    diff "$WORK/base.fn" "$WORK/ctl.fn" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.obj" "$WORK/ctl.obj"; then
    echo "  objpin    unmoved — all seven pin files build the same object-literal types."
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
    echo "  mempin    unmoved — all seven pin files resolve the same members."
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
    echo "  forkpin   unmoved — all seven pin files take the same routes and answer the same."
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

P['g01'] = ('''# THE PREMISE — both consumers reverted to the stops they carried through slice
# 106. PREDICTION: every diagnostic this chapter produces goes — 20 of them over
# six pin files — so diagcheck stays GREEN WITH A NUMBER, because a LOSS is a legal
# subsequence and that is the whole reason the stop could stand where it did. The
# diagpin is what says it, and the stop log grows by the 331 events the row used to
# carry at stage 1.''',
"""old = '''        let mark this.unported_mark()
        let before this.is_block_scoped_name_declared_before_use(decl, error_location)
        if this.unported_mark() <> mark
            return
        if before
            return'''
new = '''        this.record_unported("is-block-scoped-name-declared-before-use", f)
        if true
            return'''
old2 = '''                    let mark this.unported_mark()
                    let before this.is_block_scoped_name_declared_before_use(value_declaration, right)
                    if this.unported_mark() <> mark
                        return
                    if before = false'''
new2 = '''                    this.record_unported("is-block-scoped-name-declared-before-use", AstNode.kind_of(value_declaration))
                    let before true
                    if before = false'''""")

P['g02'] = ('''# THE POSITION TEST INVERTED — every use takes the OTHER tail. PREDICTION:
# diagcheck RED, loudly. The two tails are not each other's complement, so this is
# not a sign flip on one answer: a legal forward reference now runs the before
# tail's switch and a genuine use-before-declaration runs the after tail's deferral
# test. ★It is the row that says the split is a mechanism and not a shortcut.''',
"""old = '''        if AstNode.pos_of(declaration) <= AstNode.pos_of(usage)
        {
            set declaration_is_before: true'''
new = '''        if AstNode.pos_of(declaration) > AstNode.pos_of(usage)
        {
            set declaration_is_before: true'''""")

P['g03'] = ('''# THE BEFORE TAIL'S DEFAULT ANSWER flipped from TRUE to FALSE. PREDICTION:
# diagcheck RED by INVENTION — the tail's last line is what every kind the switch
# does NOT name falls through to, which is most of the corpus, so an ordinary
# forward-declared `let` read after its declaration becomes a TS2448. ★A default
# that is reached by everything the switch ignores cannot be gated by a fixture
# aimed at an arm, which is why the row aims at the default itself.''',
"""old = '''            return this.is_used_in_function_or_instance_property(usage, declaration, decl_container) = false
        }
        true
    }'''
new = '''            return this.is_used_in_function_or_instance_property(usage, declaration, decl_container) = false
        }
        false
    }'''""")

P['g04'] = ('''# isUsedInFunctionOrInstanceProperty FORCED TRUE — every use counts as deferred.
# PREDICTION: the after tail answers TRUE for everything it reaches, so TS2449 on
# `D`, TS2450 on `F` and TS2448 on `x` all go, and so do the property reports whose
# usage precedes the declaration. A LOSS, so diagcheck stays GREEN WITH A NUMBER
# and the diagpin carries the verdict. ★It is the SILENT port, written as one row.''',
"""old = '''            let verdict this.used_in_function_or_instance_property_at(current, usage, declaration, decl_container)
            if verdict = 2
                return false
            if verdict = 1
                return true'''
new = '''            let verdict this.used_in_function_or_instance_property_at(current, usage, declaration, decl_container)
            if verdict = 2
                return true
            if verdict = 1
                return true'''""")

P['g05'] = ('''# isUsedInFunctionOrInstanceProperty FORCED FALSE — nothing counts as deferred.
# PREDICTION: diagcheck RED by INVENTION. `later`, `stillFine` and `deferred` in
# blockscope_before_use.ts are three uses inside functions that the reference is
# silent about, and each becomes a TS2449/TS2450/TS2448. ★★It is g04's opposite
# direction and it is the LOUD port: a predicate with two failure directions needs
# both rows, and only this one is visible to a subsequence.''',
"""old = '''            let verdict this.used_in_function_or_instance_property_at(current, usage, declaration, decl_container)
            if verdict = 2
                return false
            if verdict = 1
                return true'''
new = '''            let verdict this.used_in_function_or_instance_property_at(current, usage, declaration, decl_container)
            if verdict = 2
                return false
            if verdict = 1
                return false'''""")

P['g06'] = ('''# THE `this.`-PROPERTY EXCEPTION dropped — an uninitialized property read through
# `this` counts as declared-before-use whenever it stands earlier. PREDICTION: the
# TS2729 of `Derived` goes, because `b` really is written above `a` there and only
# the exception makes the read illegal. A LOSS again, so the diagpin is the
# instrument. ★It is the reference's SECOND conjunct, the half a reader who has
# just read `declaration.Pos() <= usage.Pos()` deletes as redundant.''',
"""old = '''                            if AstNode.kind_of(AstNode.postfix_token_of(declaration)) <> KindExclamationToken
                                set declaration_is_before: false'''
new = '''                            if false
                                set declaration_is_before: false'''""")

P['g07'] = ('''# THE DEFINITE-ASSIGNMENT TEST dropped — a `!` no longer excuses an uninitialized
# property. PREDICTION: diagcheck RED 1. `Definite` in
# blockscope_property_initializer.ts is `p!: number` read from `q`'s initializer,
# the reference says nothing about it, and without this term it invents a TS2729.
# ★It is the row that says the exception's fourth conjunct is a mechanism and not a
# transcription: three conjuncts decide WHICH shape, and this one decides whether
# the author has already answered for it.''',
"""old = '''                            if AstNode.kind_of(AstNode.postfix_token_of(declaration)) <> KindExclamationToken'''
new = '''                            if true'''""")

P['g08'] = ('''# isImmediatelyUsedInInitializerOfBlockScopedVariable FORCED FALSE. PREDICTION:
# the two TS2448 of blockscope_own_initializer.ts go — `let a = a + n` and
# `let c: number = c` are the whole of the VariableDeclaration arm's input — and
# diagcheck stays GREEN WITH A NUMBER. ★The arm is the only term in the before tail
# with an input in this corpus, which is what the file was written to make true.''',
"""old = '''        if dk = KindVariableDeclaration
            return this.is_immediately_used_in_initializer_of_block_scoped_variable(declaration, usage, decl_container) = false'''
new = '''        if dk = KindVariableDeclaration
            return true'''""")

P['g09'] = ('''# isSameScopeDescendentOf's FUNCTION STOP dropped — the walk no longer leaves a
# scope at a function boundary. PREDICTION: diagcheck RED 1 by INVENTION.
# `let k = function () { return k; }` is legal and stays legal only because the
# walk stops at the function expression; without the stop it reaches the
# declaration and invents a TS2448. ★It is the row that separates the scope test
# from the position test — nothing about `pos` changes here.''',
"""old = '''            if AstNode.is_function_like(node)
            {
                if AstNode.get_immediately_invoked_function_expression(node) = null
                    return false
                if (b.get_function_flags(node) & FunctionFlagsAsyncGenerator) <> 0
                    return false
            }'''
new = '''            if false
            {
                if AstNode.get_immediately_invoked_function_expression(node) = null
                    return false
                if (b.get_function_flags(node) & FunctionFlagsAsyncGenerator) <> 0
                    return false
            }'''""")

P['g10'] = ('''# THE IIFE EXEMPTION dropped — every function-like stops the walk, immediately
# invoked or not. PREDICTION: the TS2448 of `let e: number = (function (): number
# { return e; })()` goes, a LOSS, so the diagpin is what says it. ★★Read against
# g09 it is the pair that prices the term: g09 removes the stop and invents on `k`,
# g10 removes the exemption and loses on `e`, and the file carries both spellings
# for exactly that reason.''',
"""old = '''                if AstNode.get_immediately_invoked_function_expression(node) = null
                    return false
                if (b.get_function_flags(node) & FunctionFlagsAsyncGenerator) <> 0
                    return false'''
new = '''                return false'''""")

P['g11'] = ('''# THE ASYNC-GENERATOR TERM dropped. PREDICTION: UNGATED — an immediately invoked
# async generator is a shape no unit of this corpus contains, and the row is here
# to turn that into a number rather than to be loud. ★The composite is tested for
# OVERLAP here and for EQUALITY in checkSignatureDeclaration; a reader who carries
# the second reading into this line writes `= FunctionFlagsAsyncGenerator` and the
# row would still be ungated, which is the honest thing for it to say.''',
"""old = '''                if (b.get_function_flags(node) & FunctionFlagsAsyncGenerator) <> 0
                    return false'''
new = '''                if false
                    return false'''""")

P['g12'] = ('''# isPropertyImmediatelyReferencedWithinDeclaration's `usage.End() >
# declaration.End()` EARLY RETURN dropped. PREDICTION: UNGATED, and the reason is a
# PROOF rather than a corpus gap. ★★★THE TERM IS UNREACHABLE FROM BOTH OF THIS
# CHAPTER'S CALLERS. In the AFTER tail the declaration comes textually later, so
# `usage.End() > declaration.End()` is false by construction; in the BEFORE tail the
# walk answers TRUE only when the declaration CONTAINS the usage
# (`p: number = this.p`, fixture `VV`), and then the usage ends first and the early
# return is false again. ★★MEASURED RATHER THAN ARGUED: a probe build says the early
# return FIRES ONCE over the fixtures — on `Definite` — and dropping it still changes
# no answer, because the walk then reaches the enclosing PropertyDeclaration and its
# `stop_at_any_property_declaration = false` branch returns the same FALSE one
# iteration later. So the term is reached and redundant, which is a third kind of
# ungated and not the same as g13's unreachable. ★It is written because it is the
# reference's line and a predicate narrowed to today's callers is what the next slice
# re-invents wrongly (§3.5br, §3.5by); g25 says the pair is dead together too.''',
"""old = '''        if AstNode.end_of(usage) > AstNode.end_of(declaration)
            return false'''
new = '''        if false
            return false'''""")

P['g13'] = ('''# Its ARROW-FUNCTION arm dropped. PREDICTION: UNGATED, and this row is where the
# reason for g12, g14 and g25 was finally found. ★★★THE CALLER ASKS THE SAME
# DEFERRAL QUESTION FIRST AND ITS COPY IS STRICTLY EARLIER.
# `isInPropertyInitializerOrClassStaticBlock(node, ignoreArrowFunctions=false)` QUITS
# at an arrow function and at any non-arrow function BLOCK — so a `this.x` inside an
# arrow inside a field initializer never reaches checkPropertyNotUsedBeforeDeclaration
# at all, and the walk in this function is never entered from a position an arrow or
# a method block could stop. The other caller, checkResolvedBlockScopedVariable,
# cannot reach the function either: its declarations are block-scoped variables,
# classes and enums, and both call sites here require a PropertyDeclaration or a
# parameter property. ★★So the deferral is asked TWICE on one path and each copy
# hides the other: g27 removes the caller's and is silent, this row removes the
# walk's and is silent, and g28 removes both and invents on `Y` and `Z`. ★A probe
# build confirms it directly — this arm is entered ZERO times over every fixture that
# reaches the function.''',
"""old = '''            if k = KindArrowFunction
                return false'''
new = '''            if false
                return false'''""")

P['g14'] = ('''# Its BLOCK arm dropped — a method, getter or setter body no longer defers.
# PREDICTION: UNGATED, and for a second proof rather than for g12's. ★★★THE ARM
# WANTS A METHOD BODY BETWEEN A PROPERTY-INITIALIZER USAGE AND ITS CLASS, AND
# `this` FORBIDS IT: this function is reached only with a usage inside a field
# initializer or a class static block, and the only construct that can sit between
# such a usage and the class while still resolving `this` to the instance is an
# ARROW function — and the caller has already QUIT on that (g27). An object-literal
# method or a class-expression method rebinds `this`, so its `this.x` is a different
# symbol altogether. ★It is written for g12's reason and priced by g25 and g27.''',
"""old = '''                let pk AstNode.kind_of(AstNode.parent_node_of(node))
                if pk = KindMethodDeclaration
                    return false
                if pk = KindGetAccessor
                    return false
                if pk = KindSetAccessor
                    return false'''
new = '''                let pk AstNode.kind_of(AstNode.parent_node_of(node))
                if false
                    return false'''""")

P['g15'] = ('''# isPropertyInitializedInStaticBlocks FORCED TRUE. PREDICTION: UNGATED ON ALL
# TWELVE, and that IS the measurement — blockscope_static_block.ts is the only unit
# in the stage-1 corpus that reaches this arm at all, and both readings lead to the
# same report there: with TRUE the after tail goes on to
# isPropertyImmediatelyReferencedWithinDeclaration, which answers TRUE for a
# sibling property and negates back to a report. ★The term that separates them is
# emitStandardClassFields, which g17 moves.''',
"""old = '''            if Checker.contains_undefined_type(flow_type as ref[Type]) = false
                return true
        }
        false
    }'''
new = '''            if true
                return true
        }
        false
    }'''""")

P['g16'] = ('''# The static block's POSITION WINDOW dropped — every static block of the class
# counts, wherever it stands. PREDICTION: UNGATED, with the same argument g15
# makes, and the row is here because the window is the half no flow answer gives:
# `After` assigns in a block BELOW the use and only the window rejects it. ★If this
# row is ever loud, the arm has become observable and the note in
# blockscope_static_block.ts is the one to re-read.''',
"""old = '''            let p AstNode.pos_of(member)
            if p < start_pos
                continue
            if p > end_pos
                continue'''
new = '''            let p AstNode.pos_of(member)
            if false
                continue'''""")

P['g17'] = ('''# emit_standard_class_fields FORCED FALSE. PREDICTION: the TS2729 of `Param` goes
# — a parameter property read from a field initializer is illegal only under this
# option — and the after tail stops asking
# isPropertyImmediatelyReferencedWithinDeclaration at all, which may move more. A
# LOSS, so the diagpin carries it. ★★It is the row that says the field is a SECOND
# derivation off useDefineForClassFields and not a synonym for it: the two agree
# here and would differ upstream.''',
"""old = '''        set c.emit_standard_class_fields: ScriptTargetES2025 >= ScriptTargetES2022'''
new = '''        set c.emit_standard_class_fields: false'''""")

P['g18'] = ('''# The TS2449 arm of checkResolvedBlockScopedVariable dropped. PREDICTION: the
# TS2449 on `D` goes and nothing else moves — a LOSS on one line. ★The three codes
# are one condition read through the symbol's flags, so the arms can only be priced
# one at a time, and g18/g19 are what say the chain is a chain rather than a single
# report with three spellings.''',
"""old = '''        if (f & SymbolFlagsClass) <> 0
        {
            this.error_on_node(error_location, DiagClass_0_used_before_its_declaration)
            return
        }'''
new = '''        if (f & SymbolFlagsClass) <> 0
            return'''""")

P['g19'] = ('''# The TS2450 arm dropped. PREDICTION: the TS2450 on `F` goes, and the CONST-enum
# arm below it now catches the regular enum too — which under this harness reports
# nothing, because get_isolated_modules answers false. ★★So the row loses ONE line
# and proves the fourth arm is an option rather than a code at the same time: if it
# ever loses none, isolatedModules has arrived and the arm has become live.''',
"""old = '''        if (f & SymbolFlagsRegularEnum) <> 0
        {
            this.error_on_node(error_location, DiagEnum_0_used_before_its_declaration)
            return
        }'''
new = '''        if (f & SymbolFlagsRegularEnum) <> 0
            return'''""")

P['g20'] = ('''# The DECLARATION FIND replaced by declaration ZERO. PREDICTION: UNGATED, or
# ungated with a number — every symbol this corpus routes here has its block-scoped
# declaration first. ★It is the reference's `core.Find` over a PREDICATE, and the
# predicate has three arms; a symbol merged from a function declaration and a class
# is exactly where declaration zero is the wrong one, and that shape is the
# constructor-function case the guard above already returned for. ★If it MOVES, the
# ambient test below is reading the wrong node's flags.''',
"""old = '''            let dn d as ref[AstNode]
            var block_scoped false
            if b.is_block_or_catch_scoped(dn)
                set block_scoped: true
            if Parser.is_class_like_node(dn)
                set block_scoped: true
            if AstNode.kind_of(dn) = KindEnumDeclaration
                set block_scoped: true
            if block_scoped'''
new = '''            let dn d as ref[AstNode]
            var block_scoped false
            if i = 1
                set block_scoped: true
            if block_scoped'''""")

P['g21'] = ('''# THE MARK GUARD dropped in checkResolvedBlockScopedVariable — a stop under the
# walk no longer suppresses the report. PREDICTION: diagcheck RED, or ungated with
# a number if no unit's walk stops. ★★The guard is what keeps a LOSS a loss: the
# walk reaches getTypeOfSymbol through the static arm, and reporting on an answer
# this port did not compute would be an INVENTION, which is the one thing a
# subsequence gate refuses. ★The row is here to say whether the guard is load-
# bearing today or only in principle.''',
"""old = '''        let mark this.unported_mark()
        let before this.is_block_scoped_name_declared_before_use(decl, error_location)
        if this.unported_mark() <> mark
            return'''
new = '''        let before this.is_block_scoped_name_declared_before_use(decl, error_location)'''""")

P['g22'] = ('''# THE BINDING-ELEMENT ARM dropped — it answers TRUE for every binding element.
# PREDICTION: UNGATED ON ALL TWELVE, and the row is a MEASUREMENT of the corpus and
# not of the arm. `var [a = b, b = b] = [1, 2]` is the reference's own example, and
# every spelling of it stops at get-type-for-binding-element-parent before the
# resolver gets there — probed directly on both a destructuring and an object
# pattern. ★★§3.5v calls this `uncovered`; the arm is written from the reference
# because a predicate narrowed to today's callers is what the next slice
# re-invents wrongly, and this row is what stops the next reader deleting it.''',
"""old = '''        if dk = KindBindingElement
        {'''
new = '''        if false
        {'''""")

P['g23'] = ('''# THE CLASS-LIKE ARM dropped. PREDICTION: UNGATED, for g22's reason and with its
# own probe: `class A { static p = "a"; [A.p]() {} }` stops at get-late-bound-symbol
# and `@dec(A.x) class A { static x = "x" }` at check-decorators, so neither of the
# two shapes the arm is about reaches it. ★★★Both are shapes the reference reports
# TS2449 on, so this is not a claim that the arm is dead — it is a claim about
# which chapter has to land before it can be measured, which is what a work list is
# for.''',
"""old = '''        if Parser.is_class_like_node(declaration)
            return this.class_declared_before_use(declaration, usage)'''
new = '''        if Parser.is_class_like_node(declaration)
            return true'''""")

P['g24'] = ('''# THE THREE DEFERRED-CONTEXT EXEMPTIONS dropped — JSDoc, a type query and an
# ambient or type node no longer excuse a use. PREDICTION: UNGATED ON ALL TWELVE,
# and the row carries the measurement that says why rather than a guess. A probe
# build counting every entry to this function over the stage-1 corpus reads 299
# arrivals over 115 units and **ZERO** for each of the three exemptions: the shape
# they are about is `let t: typeof w; let w = 1`, and a type query stops at
# `get-type-from-type-query-node` before any name is resolved, which was verified by
# building the patch by hand and finding it invents nothing there either. ★★It is
# §3.5v's `unreachable` with the covering stop NAMED, which is the difference
# between a row that measured something and a hole in the battery.''',
"""old = '''        if Checker.is_in_type_query(usage)
            return true
        if this.is_in_ambient_or_type_node(usage)
            return true'''
new = '''        if false
            return true'''""")

P['g25'] = ('''# THE TWO TERMS OF g12 AND g14 REMOVED TOGETHER. PREDICTION: UNGATED — and the row
# exists precisely because *masking* was the first explanation for g12 and g14 each
# coming back ungated, and it was WRONG. ★★★A PAIR OF DEAD TERMS AND A PAIR THAT
# MASK EACH OTHER LOOK IDENTICAL FROM TWO SINGLE-TERM ROWS, and the only thing that
# separates them is removing both at once: masking predicts this row is loud, two
# proofs predict it is silent. It is silent. ★★The general shape is worth more than
# this instance — whenever two single-term rows come back ungated and the terms
# stand on one path, the combined row is owed before either may be called dead.''',
"""old = '''        if AstNode.end_of(usage) > AstNode.end_of(declaration)
            return false'''
new = '''        if false
            return false'''
old2 = '''                let pk AstNode.kind_of(AstNode.parent_node_of(node))
                if pk = KindMethodDeclaration
                    return false
                if pk = KindGetAccessor
                    return false
                if pk = KindSetAccessor
                    return false'''
new2 = '''                let pk AstNode.kind_of(AstNode.parent_node_of(node))
                if false
                    return false'''""")

P['g26'] = ('''# THE WALK'S TRUE EXIT dropped — reaching the declaration no longer answers
# *immediately referenced*. PREDICTION: the TS2729 of `VV` goes. `p: number = this.p`
# is the one shape in which the read happens INSIDE the declaration it is reading,
# and the reference expresses it as a loop CONDITION (`node != declaration`) with the
# answer after the loop — which becomes a `break` here, and a `break` with no answer
# beside it reads like a miss rather than like a verdict. ★It is the row that says
# the exit is a verdict.''',
"""old = '''            if node = declaration
                return true
            let k AstNode.kind_of(node)
            if k = KindArrowFunction'''
new = '''            if node = declaration
                return false
            let k AstNode.kind_of(node)
            if k = KindArrowFunction'''""")

P['g27'] = ('''# THE CALLER'S DEFERRAL TEST WEAKENED — `isInPropertyInitializerOrClassStaticBlock`
# is asked with ignoreArrowFunctions TRUE, so an arrow no longer quits it.
# PREDICTION: diagcheck RED 2 by INVENTION on blockscope_deferred_field.ts. `Y` and
# `Z` are `t = () => this.u` over a parameter property and `a = () => this.b` over a
# plain field; the reference is silent about both, and with the caller's arrow quit
# gone they reach checkPropertyNotUsedBeforeDeclaration, run the after tail and
# report. ★★★AND IT DOES NOT, WHICH IS THE MEASUREMENT: with the caller's quit gone
# the walk's OWN arrow arm answers instead, so the deferral is asked twice on one
# path and removing either copy changes nothing. g28 removes both and is loud. ★The
# patched line is not this slice's own code, which is the point — a term's
# reachability is a property of its caller, and this row is how that gets priced.''',
"""old = '''        if Checker.is_in_property_initializer_or_class_static_block(node, false)'''
new = '''        if Checker.is_in_property_initializer_or_class_static_block(node, true)'''""")

P['g28'] = ('''# THE CALLER'S ARROW QUIT AND THE WALK'S ARROW ARM REMOVED TOGETHER. PREDICTION:
# diagcheck RED 2 by INVENTION on blockscope_deferred_field.ts — `Y` and `Z`. ★★★IT
# IS THE THIRD PAIR IN THIS BATTERY AND THE ONE THAT EXPLAINS THE OTHER TWO: the
# deferral an arrow buys is asked TWICE on one path, once by
# isInPropertyInitializerOrClassStaticBlock before the chapter is entered and once by
# isPropertyImmediatelyReferencedWithinDeclaration inside it, so g13 and g27 are each
# silent and the pair is loud. ★★A probe build counting arrivals says the same thing
# from the other side: over the two fixtures that reach this function at all, the
# walk is entered THREE times, its End() early return fires once and its ARROW arm
# never — because the caller quit first.''',
"""old = '''        if Checker.is_in_property_initializer_or_class_static_block(node, false)'''
new = '''        if Checker.is_in_property_initializer_or_class_static_block(node, true)'''
old2 = '''            if k = KindArrowFunction
                return false'''
new2 = '''            if false
                return false'''""")

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

control "g01 THE PREMISE — both consumers back to their stops" $CHECKER "$PATCHDIR/g01.py"
control "g02 THE POSITION TEST inverted" $CHECKER "$PATCHDIR/g02.py"
control "g03 the BEFORE TAIL's default answer flipped" $CHECKER "$PATCHDIR/g03.py"
control "g04 isUsedInFunctionOrInstanceProperty forced TRUE" $CHECKER "$PATCHDIR/g04.py"
control "g05 isUsedInFunctionOrInstanceProperty forced FALSE" $CHECKER "$PATCHDIR/g05.py"
control "g06 the this-property EXCEPTION dropped" $CHECKER "$PATCHDIR/g06.py"
control "g07 the DEFINITE-ASSIGNMENT test dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 isImmediatelyUsedInInitializer... forced FALSE" $CHECKER "$PATCHDIR/g08.py"
control "g09 isSameScopeDescendentOf's FUNCTION STOP dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 the IIFE EXEMPTION dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the ASYNC-GENERATOR term dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the End() EARLY RETURN dropped" $CHECKER "$PATCHDIR/g12.py"
control "g13 the ARROW-FUNCTION arm dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 the BLOCK arm dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 isPropertyInitializedInStaticBlocks forced TRUE" $CHECKER "$PATCHDIR/g15.py"
control "g16 the static block's POSITION WINDOW dropped" $CHECKER "$PATCHDIR/g16.py"
control "g17 emit_standard_class_fields forced FALSE" $CHECKER "$PATCHDIR/g17.py"
control "g18 the TS2449 arm dropped" $CHECKER "$PATCHDIR/g18.py"
control "g19 the TS2450 arm dropped" $CHECKER "$PATCHDIR/g19.py"
control "g20 the DECLARATION FIND replaced by declaration ZERO" $CHECKER "$PATCHDIR/g20.py"
control "g21 THE MARK GUARD dropped" $CHECKER "$PATCHDIR/g21.py"
control "g22 THE BINDING-ELEMENT ARM dropped" $CHECKER "$PATCHDIR/g22.py"
control "g23 THE CLASS-LIKE ARM dropped" $CHECKER "$PATCHDIR/g23.py"
control "g24 the THREE DEFERRED-CONTEXT EXEMPTIONS dropped" $CHECKER "$PATCHDIR/g24.py"
control "g25 the End() EARLY RETURN and the BLOCK arm dropped TOGETHER" $CHECKER "$PATCHDIR/g25.py"
control "g26 THE WALK'S TRUE EXIT dropped" $CHECKER "$PATCHDIR/g26.py"
control "g27 THE CALLER'S DEFERRAL TEST weakened" $CHECKER "$PATCHDIR/g27.py"
control "g28 THE CALLER'S ARROW QUIT and THE WALK'S ARROW ARM together" $CHECKER "$PATCHDIR/g28.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
