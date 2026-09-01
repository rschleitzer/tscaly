#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice104.sh — the slice-104 battery: THE GLOBALS TABLE'S BUILDABLE HALF.
#
# ★★★ THE DEFERRAL THIS DISCHARGES WAS WRITTEN AT THE LINE IT CHANGES, BY SLICE 91,
# AND IT NAMED ITS OWN EXPIRY. lookup_globals' note read: *"A GLOBAL (non-module)
# source file's own locals are merged into globals upstream, and
# `is_global_source_file` is exactly why the loop above skips them — so a script
# file's top-level names are unreachable here on BOTH routes. Giving this function
# the file's locals when the file is a global source file would be a strict
# improvement and still a subset of upstream's table; it is deliberately not done in
# this slice, because it would mix a measurable change into the one commit whose
# value is the walk."* Thirteen slices later, this is that measurable change.
#
# ★★★ WHAT IS PORTED IS initializeChecker MINUS THE LIB: the non-module file's
# locals merged (with the globalThis conflict report and the ambient-module
# deferral), mergeGlobalSymbol, the UMD GlobalExports merge,
# addUndefinedToGlobalsOrErrorOnRedeclaration, the two eager resolvedType
# assignments this port can make, and lookup_globals reading the table. The LIB half
# is §3.11 and stays reported.
#
# ★★★ NO NEW INSTRUMENT, AND THAT IS AN ARGUMENT RATHER THAN A SAVING. This slice's
# product is visible on FOUR instruments that already exist — diagcheck gains two
# report families it could not reach, the STOP histogram loses 511 events on one
# row, the RELGATE gains comparisons whose operands finally have types, and the
# KINDGATE and FORKGATE LOSE rows, because an operand that used to be the error type
# now has a real one. A pin that only ever grows would have hidden the last of
# those, which is the finding this battery is built around.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice104.sh 2>&1 | tee /tmp/battery104.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice104.sh g08 g10` runs the baseline and
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

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# ★ ONE MECHANISM PER FILE (slice 72's rule). FOUR of this slice's own and ONE
# borrowed: the merge loop (a script file's own names), the two reports
# initializeChecker makes (and the IsTypeDeclaration exemption that keeps the third
# quiet), what a MODULE gets out of the table — which is the seeded pair and not its
# own names — the UMD half, and slice 97's `this` fixture, whose header named this
# very wall and now reads the arm that answers.
PINFILES="
$FIX/globals_script.ts
$FIX/globals_conflicts.ts
$FIX/globals_module.ts
$FIX/globals_umd.d.ts
$FIX/thisexpr_stops.ts
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

WORK=$(mktemp -d -t tscaly-ctl104)

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
A = {}   # rows that patch ast.scaly instead of checker.scaly

P['g01'] = ('''# THE PREMISE — lookup_globals reverted to the `null` it answered through thirteen
# slices. PREDICTION: this slice, in one row. Everything the table can be asked is
# asked through this one line, so a revert here is the whole chapter and nothing
# else — the reports initializeChecker makes on its own are NOT behind it, which is
# what separates this row from g02.''',
'''old = """    function lookup_globals(this, name_data: pointer[char], name_len: int, meaning: int) returns ref[Symbol]?
        this.lookup_symbol(globals, name_data, name_len, meaning)"""
new = """    function lookup_globals(this, name_data: pointer[char], name_len: int, meaning: int) returns ref[Symbol]?
        null"""''')

P['g02'] = ('''# THE WHOLE OF initialize_checker SKIPPED — the table stays as create() left it,
# holding globalThis alone. PREDICTION: g01 plus the two report families, so this
# row is strictly larger than g01 and the difference between them is exactly what
# initializeChecker contributes that is NOT a lookup.''',
'''old = """    procedure initialize_checker(this)
    {"""
new = """    procedure initialize_checker(this)
    {
        return"""''')

P['g03'] = ('''# The non-module GUARD dropped: a MODULE's locals merged into globals too.
# PREDICTION: a WRONG answer, and the direction diagcheck can see. A module's
# top-level names are already found by resolve_name's walk, so the extra table entry
# changes nothing for them — but `export {}` makes a file a module and its names are
# then ALSO globals, which upstream they are not, and block 2 of
# on_successfully_resolved_symbol reports TS2686 on a UMD global reached from a
# module. If nothing moves, the row says the walk gets there first every time.''',
'''old = """        if b.is_external_or_common_js_module() = false
        {
            let locals AstNode.locals_of(file)"""
new = """        if true
        {
            let locals AstNode.locals_of(file)"""''')

P['g04'] = ('''# The globalThis CONFLICT REPORT dropped. PREDICTION: diagcheck loses one TS2397
# (a LOSS is a legal subsequence, so it stays green WITH A NUMBER) and the diagpin
# moves on globals_conflicts.ts. The merge that follows still runs, so
# merge-global-symbol still stops — which is what tells this row apart from g06.''',
'''old = """                    this.error_on_node(Symbol.declaration_at(ogt, di), DiagDeclaration_name_conflicts_with_built_in_global_identifier_0)
                    set di: di + 1"""
new = """                    set di: di + 1"""''')

P['g05'] = ('''# The globalThis conflict report moved from a LOOP over the declarations to the
# FIRST declaration only. PREDICTION: UNGATED — no fixture and no corpus unit
# declares `globalThis` twice, which the row states with a number instead of a
# sentence.''',
'''old = """                let dn Symbol.declaration_count(ogt)"""
new = """                var dn Symbol.declaration_count(ogt)
                if dn > 1
                    set dn: 1"""''')

P['g06'] = ('''# globalThis NOT SEEDED into the table by create(). PREDICTION: three things at
# once, and they are worth separating in the report — the conflict report survives
# (it reads the FILE's locals, not the table), merge_global_symbol stops firing
# because there is nothing left to collide with, and `globalThis` in an expression
# resolves to whatever the file declared instead of to the built-in symbol.''',
'''old = """        SymbolTable.set_entry(host, g, global_this_data, global_this_len, gts)"""
new = """        ; g06: not seeded"""''')

P['g07'] = ('''# The AMBIENT-MODULE DEFERRAL dropped: every local merged in the first pass.
# PREDICTION: UNGATED, and PREDICTED FROM A CLOSED LIST. What sits between the two
# passes upstream is the creation of the global TYPES, and this port creates none —
# so with one file the two orders are the same order.''',
'''old = """                    if deferred
                    {
                        if ambient = null
                            set ambient: &Array[ref[Symbol]?]^host()
                        (ambient as ref[Array[ref[Symbol]?]]).add(sy)
                    }
                    else
                        this.merge_global_symbol(sy)"""
new = """                    this.merge_global_symbol(sy)"""''')

P['g08'] = ('''# is_ambient_module_symbol_name forced TRUE for every symbol — so every local is
# deferred to the second pass. PREDICTION: UNGATED for g07's reason, from the other
# side: if the two passes are indistinguishable, moving EVERYTHING to the second one
# must also be.''',
'''old = """        if name_len < 2
            return false
        if *name_data <> "\\\\""
            return false
        *(name_data + (name_len - 1)) = "\\\\"" """.rstrip() + """"""
new = """        true"""'''.replace('\\\\\\\\','\\\\'))

P['g09'] = ('''# The UMD GlobalExports merge dropped. PREDICTION: UNGATED, and globals_umd.d.ts
# is the fixture that says why with a stop rather than a sentence — the table is
# filled only in a DECLARATION file, a declaration file has no value expressions,
# and the one route left is a type query that stops one chapter earlier at
# `get-type-from-type-query-node`.''',
'''old = """                if SymbolTable.get(globals, nd, nl) = null
                    SymbolTable.set_entry(host, globals, nd, nl, sym)"""
new = """                set gi: gi"""''')

P['g10'] = ('''# The UMD merge's FIRST-IN-WINS turned into last-in-wins. PREDICTION: UNGATED, and
# for a sharper reason than g09's: a single file's GlobalExports table can only
# collide with a name already in globals, i.e. with `globalThis` — and the binder
# writes an `export as namespace` name, which cannot be that.''',
'''old = """                if SymbolTable.get(globals, nd, nl) = null
                    SymbolTable.set_entry(host, globals, nd, nl, sym)"""
new = """                SymbolTable.set_entry(host, globals, nd, nl, sym)"""''')

P['g11'] = ('''# `undefined` NOT SEEDED into the table (addUndefinedToGlobals' else branch
# dropped). PREDICTION: the single largest row of the battery after g01/g02 — every
# `undefined` in the corpus goes back to `resolve-name-not-found` — and the report
# branch is untouched, which is what separates it from g12.''',
'''old = """        if target = null
        {
            SymbolTable.set_entry(host, globals, nd, nl, undefined_symbol)
            return
        }"""
new = """        if target = null
            return"""''')

P['g12'] = ('''# addUndefinedToGlobals' REPORT branch dropped. PREDICTION: diagcheck loses one
# TS2397 and the diagpin moves on globals_conflicts.ts, while every resolution is
# untouched — g11 from the other side.''',
'''old = """            if Checker.is_type_declaration(d) = false
                this.error_on_node(d, DiagDeclaration_name_conflicts_with_built_in_global_identifier_0)"""
new = """            set i: i"""''')

P['g13'] = ('''# is_type_declaration forced FALSE. PREDICTION: diagcheck RED — an INVENTED TS2397
# on `interface undefined`, which is the one direction the subsequence relation
# catches, and the reason the predicate is ported rather than assumed.''',
'''old = """    function is_type_declaration(node: ref[AstNode]?) returns bool
    {
        if node = null
            return false"""
new = """    function is_type_declaration(node: ref[AstNode]?) returns bool
    {
        if node <> null
            return false
        if node = null
            return false"""''')

P['g14'] = ('''# is_type_declaration forced TRUE. PREDICTION: the LOSS direction of g13 — the
# TS2397 on `declare var undefined` disappears, diagcheck stays green with a smaller
# number, and only the diagpin says so. A predicate with two failure directions
# needs both rows.''',
'''old = """        let k AstNode.kind_of(n)
        if k = KindTypeParameter
            return true"""
new = """        let k AstNode.kind_of(n)
        if k <> KindTypeParameter
            return true
        if k = KindTypeParameter
            return true"""''')

P['g15'] = ('''# The eager `undefined` resolvedType assignment dropped. PREDICTION: the name still
# resolves and the TYPE does not, so the corpus moves from a resolution stop to a
# TYPE stop — the sharpest single row for the claim that the seeded symbol and its
# eager type are two mechanisms and not one. globals_module.ts's TS2322 is the pin.''',
'''old = """        let ul this.value_symbol_link_of(undefined_symbol)
        set ul.resolved_type: undefined_widening_type"""
new = """        ; g15: no eager type for undefined"""''')

P['g16'] = ('''# The eager globalThis resolvedType assignment dropped. PREDICTION: the `this`
# arm's answer becomes null, so slice 97's fixture reads arm 0 instead of arm 6 and
# the relgate loses the two rows the arm feeds.''',
'''old = """        let gl this.value_symbol_link_of(global_this_symbol)
        set gl.resolved_type: this.new_object_type(ObjectFlagsAnonymous, global_this_symbol)"""
new = """        ; g16: no eager type for globalThis"""''')

P['g17'] = ('''# The `this`-at-top-level arm reverted to the STOP slice 97 wrote there.
# PREDICTION: `global-this-type` comes back with its four events and the relgate
# loses two rows — the same two g16 removes, by a different mechanism, which is what
# makes the pair worth running.''',
'''old = """                set out_arm: 6
                return this.get_type_of_symbol(global_this_symbol)"""
new = """                this.record_unported("global-this-type", KindSourceFile)
                return null"""''')

P['g18'] = ('''# merge_global_symbol's COLLISION arm STORES instead of stopping — the silent wrong
# answer the arm exists to refuse. PREDICTION: it must MOVE something, or the stop
# is a hedge rather than a refusal. globals_conflicts.ts is where: `globalThis`
# resolves to the file's own symbol instead of the built-in one.''',
'''old = """            this.record_unported("merge-global-symbol", Symbol.flags_of(symbol))
            return"""
new = """            SymbolTable.set_entry(host, globals, nd, nl, symbol)
            return"""''')

P['g19'] = ('''# merge_global_symbol's get_merged_symbol call replaced by the symbol itself.
# PREDICTION: UNGATED, and it is the row that DATES get_merged_symbol's own note.
# That function is the identity because c.mergedSymbols has no writer, and this
# slice does not give it one — mergeSymbol is the successor, not this.''',
'''old = """        SymbolTable.set_entry(host, globals, nd, nl, this.get_merged_symbol(symbol))"""
new = """        SymbolTable.set_entry(host, globals, nd, nl, symbol)"""''')

P['g20'] = ('''# The GlobalLookup bit dropped from the meaning passed to lookup_globals.
# PREDICTION: UNGATED — its only reader upstream is the spelling suggester, which
# needs the lib before it has an input, and lookup_symbol masks with SymbolFlagsAll,
# which excludes bit 30 by construction.''',
'''old = """                set result: this.lookup_globals(name_data, name_len, meaning | SymbolFlagsGlobalLookup)"""
new = """                set result: this.lookup_globals(name_data, name_len, meaning)"""''')

P['g21'] = ('''# initialize_checker's ORDER inverted: addUndefinedToGlobals BEFORE the merge loop.
# PREDICTION: it MOVES, and the mechanism is the one the reference's order exists
# for — with `undefined` in the table first, a file declaring its own takes
# merge_global_symbol's collision arm instead of the report branch, so the TS2397
# turns into a stop.''',
'''old = """        this.add_undefined_to_globals_or_error_on_redeclaration()"""
new = """        ; g21: moved to the top"""
old2 = """        var ambient: ref[Array[ref[Symbol]?]]? null"""
new2 = """        var ambient: ref[Array[ref[Symbol]?]]? null
        this.add_undefined_to_globals_or_error_on_redeclaration()"""'''
)

P['g22'] = ('''# `undefined` seeded with the WRONG FLAGS (Type instead of Property). PREDICTION:
# the name is in the table and every VALUE-meaning lookup misses it, because
# lookup_symbol tests `flags & meaning`. The row exists to prove the resolutions
# this slice buys go through the MEANING test and not merely through the name.''',
'''old = """        set c.undefined_symbol: Symbol.create(host, SymbolFlagsProperty, undefined_data, undefined_len)"""
new = """        set c.undefined_symbol: Symbol.create(host, SymbolFlagsTypeAlias, undefined_data, undefined_len)"""''')

P['g23'] = ('''# globalThis seeded with the wrong flags (Property instead of Module).
# PREDICTION: g22's argument on the other symbol, plus one more — getTypeOfSymbol
# routes a Property to getTypeOfVariableOrParameterOrProperty, which does NOT read
# the links slot initialize_checker filled, so the `this` arm loses its answer too.''',
'''old = """        let gts Symbol.create(host, SymbolFlagsModule, global_this_data, global_this_len)"""
new = """        let gts Symbol.create(host, SymbolFlagsProperty, global_this_data, global_this_len)"""''')

A['g24'] = ('''# Symbol.set_exports NOT wired — globalThis carries no exports table.
# PREDICTION: UNGATED, and it is a claim about the FUTURE rather than about today:
# the slot's reader is a property access on `globalThis`, which needs
# resolveStructuredTypeMembers over a module symbol. A row that predicts UNGATED and
# says which slice expires it is a measurement (§3.5be).''',
'''old = """    procedure set_exports(s: ref[Symbol], t: ref[SymbolTable])
        set s.exports: t"""
new = """    procedure set_exports(s: ref[Symbol], t: ref[SymbolTable])
        set s.exports: s.exports"""''')

for name, (why, body) in list(P.items()) + list(A.items()):
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

control "g01 THE PREMISE — lookup_globals reverted to null" $CHECKER "$PATCHDIR/g01.py"
control "g02 the WHOLE of initialize_checker skipped" $CHECKER "$PATCHDIR/g02.py"
control "g03 the non-module GUARD dropped (a module's locals merged too)" $CHECKER "$PATCHDIR/g03.py"
control "g04 the globalThis CONFLICT REPORT dropped" $CHECKER "$PATCHDIR/g04.py"
control "g05 that report narrowed to the FIRST declaration" $CHECKER "$PATCHDIR/g05.py"
control "g06 globalThis NOT seeded into the table" $CHECKER "$PATCHDIR/g06.py"
control "g07 the AMBIENT-MODULE deferral dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 is_ambient_module_symbol_name forced TRUE" $CHECKER "$PATCHDIR/g08.py"
control "g09 the UMD GlobalExports merge dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 the UMD merge's FIRST-IN-WINS turned into last-in-wins" $CHECKER "$PATCHDIR/g10.py"
control "g11 undefined NOT seeded into the table" $CHECKER "$PATCHDIR/g11.py"
control "g12 addUndefinedToGlobals' REPORT branch dropped" $CHECKER "$PATCHDIR/g12.py"
control "g13 is_type_declaration forced FALSE" $CHECKER "$PATCHDIR/g13.py"
control "g14 is_type_declaration forced TRUE" $CHECKER "$PATCHDIR/g14.py"
control "g15 the eager undefined resolvedType assignment dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 the eager globalThis resolvedType assignment dropped" $CHECKER "$PATCHDIR/g16.py"
control "g17 the this-at-top-level arm reverted to slice 97's stop" $CHECKER "$PATCHDIR/g17.py"
control "g18 merge_global_symbol's COLLISION arm STORES instead of stopping" $CHECKER "$PATCHDIR/g18.py"
control "g19 merge_global_symbol's get_merged_symbol call dropped" $CHECKER "$PATCHDIR/g19.py"
control "g20 the GlobalLookup bit dropped from the meaning" $CHECKER "$PATCHDIR/g20.py"
control "g21 initialize_checker's ORDER inverted" $CHECKER "$PATCHDIR/g21.py"
control "g22 undefined seeded with the WRONG FLAGS" $CHECKER "$PATCHDIR/g22.py"
control "g23 globalThis seeded with the WRONG FLAGS" $CHECKER "$PATCHDIR/g23.py"
control "g24 Symbol.set_exports NOT wired" $AST "$PATCHDIR/g24.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
