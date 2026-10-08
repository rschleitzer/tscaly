#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice101.sh — the slice-101 battery: THE ASSIGNABILITY RELATION, the
# half of it that answers without recursing.
#
# ★★★ THE ROW SLICES 99 AND 100 BOTH NAMED AND NEITHER TOOK. Both closing
# paragraphs called `check-type-assignable-to 261` *the largest row that is not the
# table* — 2 234 units of stage 2, then 2 783 — and both passed it over for the same
# reason: relater.go is 5 006 lines of ONE recursive comparison with a dozen entry
# points, so it cannot be opened as a dispatch and closed arm by arm. What this
# slice takes is the half that answers WITHOUT recursing: isTypeRelatedTo,
# isSimpleTypeRelatedTo, and the report where NEITHER side is structured or
# instantiable.
#
# ★★★ THE SAFETY OF THE REPORT IS ONE GUARD IN TWO HALVES AND THIS BATTERY HAS A
# ROW FOR EACH (g29, g30), because the second half was missing once and STAGE 2 is
# what said so. The first is the MARK: a diagnostic is emitted only when nothing
# stopped inside the comparison. The second is the ERROR TYPE — `error_type`
# carries TypeFlagsAny, so it answers TRUE against everything EXCEPT a `never`
# target, where the fourth arm of isSimpleTypeRelatedTo answers FALSE first. That
# is `let t: never = x` in a narrowed else-branch, twice in 18 293 units, where the
# reference narrows to never and this port answers the error type; both invented a
# TS2322 the reference does not have, which is the one direction a SUBSEQUENCE
# relation can see.
#
# ★★★ THE FOURTEENTH INSTRUMENT, AND ITS ARGUMENT IS THAT THIS CHAPTER'S COMMONEST
# PRODUCT IS AN ABSENCE. A relation that answers TRUE emits no diagnostic, writes no
# type, moves no member table and — now that the stop it replaced is gone — leaves
# nothing in the stop log either. So the whole fifteen-arm flag table is invisible
# to every other instrument here: a control that breaks an arm the TRUE way moves a
# diagcheck count only where the comparison also happened to be reportable, and one
# that breaks it the other way moves nothing at all. `tscaly_types --relations`
# prints `A <pos> <source flags> <target flags> <verdict>`, verdict 1 RELATED, 0 NOT
# RELATED, 2 COULD NOT ANSWER.
#
# ★★★ THE HAND COUNT THAT LICENSES THE NUMBERS BELOW: `--relations` over the five
# pin files reads 27 rows across all three verdicts, both report paths and the two
# elaborator recursion arms; the whole-corpus RELGATE reads 757 rows over 1 444
# units, of which 735 answer RELATED, 13 report and 9 could not answer. Against them
# stand the 882 stop events the four `check-type-assignable-to` rows carried at stage
# 1 — arrival is not an answer, and the difference went to answers rather than to
# nothing.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice101.sh 2>&1 | tee /tmp/battery101.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice101.sh g17 g19` runs the baseline and
# then only the named rows. ★The baseline is NEVER skipped: every verdict below is
# a comparison against it.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Five files: the arms that answer
# TRUE, the arms that answer FALSE and therefore REPORT, the pairs that must STOP
# rather than answer, the elaborator's one reachable population (an OBJECT source
# against a PRIMITIVE target) and the assignment operator's own site, which is the
# only one of the three whose target type is rewritten before the comparison.
PINFILES="
$FIX/rel_primitives.ts
$FIX/rel_report.ts
$FIX/rel_structured.ts
$FIX/rel_elaborate.ts
$FIX/rel_assignment.ts
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

WORK=$(mktemp -d -t tscaly-ctl101)

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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; REL_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — eight instruments"
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
  fnpin_of > "$WORK/base.fn"
  objpin_of > "$WORK/base.obj"
  mempin_of > "$WORK/base.mem"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.mts' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  REL_BASE=$(relgate)
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
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             relgate   (rows related notrelated couldnotanswer checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $REL_BASE"
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
  fnpin_of > "$WORK/ctl.fn"
  objpin_of > "$WORK/ctl.obj"
  mempin_of > "$WORK/ctl.mem"
  stop=$(stopgate)
  local rel_g
  rel_g=$(relgate)
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
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all eight, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL EIGHT AND NOTHING MOVED AT ALL."
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

P['g01'] = ('''# THE PREMISE — the VARIABLE DECLARATION's call reverted to the stop it carried for
# thirty-one slices. PREDICTION: everything moves. It is the site that produced
# `check-type-assignable-to 261`, the head of the work list on both stages.''',
'''old = """                        this.check_type_assignable_to_and_optionally_elaborate(initializer_type as ref[Type], symbol_type as ref[Type], node, initializer)"""
new = """                        this.record_unported("check-type-assignable-to", AstNode.kind_of(node))"""''')

P['g02'] = ('''# The ASSIGNMENT OPERATOR's call reverted to its stop. PREDICTION: the relgate's
# ROW count falls by the assignment rows alone and the declaration's stand.''',
'''old = """        this.check_type_assignable_to_and_optionally_elaborate(right_type as ref[Type], target_type as ref[Type], left, right)"""
new = """        this.record_unported("check-type-assignable-to", AstNode.kind_of(left))"""''')

P['g03'] = ('''# The PROPERTY ASSIGNMENT's call reverted to its stop. PREDICTION: a small move on
# the corpus and none on the fixtures — an annotated property assignment is a JSDoc
# shape in a .js file, which is why the row was small where the declaration's was
# the largest on the list.''',
'''old = """        if t <> null
            this.check_type_assignable_to_and_optionally_elaborate(initializer_type as ref[Type], t as ref[Type], node, initializer)
        t"""
new = """        this.record_unported("check-type-assignable-to", KindPropertyAssignment)
        t"""''')

P['g04'] = ('''# The COMPOUND ASSIGNMENT's write-type rewrite dropped: the relation is asked about
# the type this procedure was handed rather than the one the write-only property
# access answered. PREDICTION: a WELL-FORMED WRONG comparison, which is the shape
# this file is organised against — and the only instrument that can see it is the
# relpin's target column.''',
'''old = """        var target_type: ref[Type]? left_type
        if Parser.is_compound_assignment(op_kind)
        {
            if AstNode.kind_of(left) = KindPropertyAccessExpression
                set target_type: write_type
        }"""
new = """        var target_type: ref[Type]? left_type"""''')

P['g05'] = ('''# isSimpleTypeRelatedTo's FIRST arm — `t&Any` — dropped. PREDICTION: every
# comparison against `any` or the error type stops answering; the relgate's RELATED
# count falls hard and COULD-NOT-ANSWER rises.''',
'''old = """        if (t & TypeFlagsAny) <> 0
            return true
        if (s & TypeFlagsNever) <> 0"""
new = """        if (s & TypeFlagsNever) <> 0"""''')

P['g06'] = ('''# The `s&Never` arm dropped — never is assignable to everything. PREDICTION: the
# relgate moves only where a never-typed source reaches a comparison, which this
# port can produce only through a narrowing it mostly does not have. A row that
# says how much of the never population is real.''',
'''old = """        if (s & TypeFlagsNever) <> 0
            return true
        if source = wildcard_type"""
new = """        if source = wildcard_type"""''')

P['g07'] = ('''# The WILDCARD disjunct dropped. PREDICTION: UNGATED — nothing in this port mints
# a wildcard type; it is created by the inference machinery's mapper, which is a
# dimension away. Written as the reference's test rather than folded away.''',
'''old = """        if source = wildcard_type
            return true
"""
new = """"""''')

P['g08'] = ('''# The `t&Unknown` arm dropped. PREDICTION: `var k: unknown = "a"` in
# rel_primitives.ts stops answering — the relpin's verdict column moves on one row
# and the diagpin does not, because unknown is not structured and the report the
# fall-through would make is one the reference does not have.''',
'''old = """            if excluded = false
                return true
        }
        if (t & TypeFlagsNever) <> 0"""
new = """        }
        if (t & TypeFlagsNever) <> 0"""''')

P['g09'] = ('''# The `t&Never` arm — the one that answers FALSE — dropped. PREDICTION: a never
# TARGET starts falling through to the arms below it, and the two units the
# error-type guard was written for change verdict again. The row that says an arm
# answering FALSE is as load-bearing as one answering TRUE.''',
'''old = """        if (t & TypeFlagsNever) <> 0
            return false
        if (s & TypeFlagsStringLike) <> 0"""
new = """        if (s & TypeFlagsStringLike) <> 0"""''')

P['g10'] = ('''# The StringLike/String arm dropped. PREDICTION: `var s: string = "a"` reports
# TS2322 — an INVENTED line, the direction a SUBSEQUENCE relation can see, so
# diagcheck goes RED as well as the diagpin.''',
'''old = """        if (s & TypeFlagsStringLike) <> 0
        {
            if (t & TypeFlagsString) <> 0
                return true
        }"""
new = """"""''')

P['g11'] = ('''# The NumberLike/Number arm dropped. PREDICTION: g10 for numbers, and it is the
# larger population — every un-annotated `var x = 1` is a number literal against
# the widened number type.''',
'''old = """        if (s & TypeFlagsNumberLike) <> 0
        {
            if (t & TypeFlagsNumber) <> 0
                return true
        }"""
new = """"""''')

P['g12'] = ('''# The BigIntLike/BigInt arm dropped. PREDICTION: one row of rel_primitives.ts and
# very little of the corpus — the smallest of the five literal families.''',
'''old = """        if (s & TypeFlagsBigIntLike) <> 0
        {
            if (t & TypeFlagsBigInt) <> 0
                return true
        }"""
new = """"""''')

P['g13'] = ('''# The BooleanLike/Boolean arm dropped. PREDICTION: UNGATED OR NEARLY SO, and the
# reason is a type this port builds correctly: `boolean` is a UNION of its two
# literals, so a boolean target is structured and stops one line later whatever
# this arm answers. The arm only fires where the target is the intrinsic Boolean.''',
'''old = """        if (s & TypeFlagsBooleanLike) <> 0
        {
            if (t & TypeFlagsBoolean) <> 0
                return true
        }"""
new = """"""''')

P['g14'] = ('''# The ESSymbolLike/ESSymbol arm dropped. PREDICTION: UNGATED — a symbol-typed
# expression needs the globals table (§3.11) to be typed at all.''',
'''old = """        if (s & TypeFlagsESSymbolLike) <> 0
        {
            if (t & TypeFlagsESSymbol) <> 0
                return true
        }"""
new = """"""''')

P['g15'] = ('''# The UNDEFINED arm dropped. PREDICTION: `var v: void = undefined` and
# `var u: undefined = undefined` change verdict — but only where `undefined` is
# typed, and that name is a GLOBAL this port does not resolve, so the corpus half
# may be smaller than the fixture half. A row about §3.11 as much as about the arm.''',
'''old = """        if (s & TypeFlagsUndefined) <> 0
        {
            if Checker.strict_null_checks() = false
            {
                if (t & TypeFlagsUnionOrIntersection) = 0
                    return true
            }
            if (t & (TypeFlagsUndefined | TypeFlagsVoid)) <> 0
                return true
        }"""
new = """"""''')

P['g16'] = ('''# The NULL arm dropped. PREDICTION: `var nl: null = null` changes verdict. Unlike
# `undefined`, the null literal is a KEYWORD and needs no globals table, so this
# row and g15 are not the same row twice.''',
'''old = """        if (s & TypeFlagsNull) <> 0
        {
            if Checker.strict_null_checks() = false
            {
                if (t & TypeFlagsUnionOrIntersection) = 0
                    return true
            }
            if (t & TypeFlagsNull) <> 0
                return true
        }"""
new = """"""''')

P['g17'] = ('''# The Object/NonPrimitive arm dropped — `var p: object = { a: 1 }`. PREDICTION:
# the relpin's third row in rel_structured.ts goes from RELATED to a REPORT, so the
# diagpin moves and diagcheck goes RED on an invented line.''',
'''old = """        if (s & TypeFlagsObject) <> 0
        {
            if (t & TypeFlagsNonPrimitive) <> 0
            {
                if relation <> RelationStrictSubtype
                    return true
                this.record_unported("is-empty-anonymous-object-type", source.object_flags)
            }
        }"""
new = """"""''')

P['g18'] = ('''# The assignable block's `s&Any` arm dropped — the one that makes `any` assignable
# to everything. PREDICTION: large. It is not g05 twice: g05 is about the TARGET
# being any, this is about the SOURCE, and this port produces an any-typed source
# every time a chapter it does not have hands back the error type.''',
'''old = """            if (s & TypeFlagsAny) <> 0
                return true
            ; "Type number is assignable to any computed numeric enum type or any"""
new = """            ; "Type number is assignable to any computed numeric enum type or any"""''')

P['g19'] = ('''# The two ENUM STOPS removed, so the enum arms answer FALSE instead of reporting.
# PREDICTION: UNGATED, and the containment is the point — nothing in this port sets
# TypeFlagsEnum or TypeFlagsEnumLiteral on a type, which get_widened_literal_type's
# own note has said since slice 72 and compute-enum-member-values says from the
# other side.''',
'''old = """        if (s & TypeFlagsEnum) <> 0
        {
            if (t & TypeFlagsEnum) <> 0
                this.record_unported("is-enum-type-related-to", s)
        }
        if (s & TypeFlagsEnumLiteral) <> 0
        {
            if (t & TypeFlagsEnumLiteral) <> 0
                this.record_unported("is-enum-type-related-to", s)
        }"""
new = """"""''')

P['g20'] = ('''# The FRESH-LITERAL normalization dropped in isTypeRelatedTo. PREDICTION: the
# identity test below it stops firing for every literal — a fresh `"a"` and the
# regular `"a"` are two objects — and the relgate's checksum moves even where the
# verdicts do not.''',
'''old = """        var s: ref[Type] source
        if Checker.is_fresh_literal_type(s)
        {
            let sr Checker.literal_regular_type_of(s)
            if sr <> null
                set s: sr as ref[Type]
        }
        var t: ref[Type] target
        if Checker.is_fresh_literal_type(t)
        {
            let tr Checker.literal_regular_type_of(t)
            if tr <> null
                set t: tr as ref[Type]
        }
        if s = t
            return true"""
new = """        var s: ref[Type] source
        var t: ref[Type] target
        if s = t
            return true"""''')

P['g21'] = ('''# The IDENTITY test `s = t` dropped from isTypeRelatedTo. PREDICTION: every
# comparison of a type with itself falls through to the flag arms, and the ones the
# flag arms cannot answer — two object types, a union with itself — become
# COULD-NOT-ANSWER rows.''',
'''old = """        if s = t
            return true
        if relation <> RelationIdentity"""
new = """        if relation <> RelationIdentity"""''')

P['g22'] = ('''# The STRUCTURED branch answers FALSE instead of stopping. PREDICTION: diagcheck
# RED and the largest invented-line count in the battery — every object-to-object
# and union comparison in the corpus becomes a TS2322. The row that says the stop
# is the product, not a placeholder.''',
'''old = """            this.record_unported("structured-type-related-to", source.flags)
            return false"""
new = """            return false"""''')

P['g23'] = ('''# The OBJECT-SOURCE / PRIMITIVE-TARGET early branch removed, so the pair falls
# through to normalization and then to the structured branch. PREDICTION: every
# `var x: string = {}` becomes a row instead of a diagnostic — the diagpin loses
# rel_elaborate.ts's whole C section and the relgate's NOT-RELATED count falls.''',
'''old = """        if (original_source.flags & TypeFlagsObject) <> 0
        {
            if (original_target.flags & TypeFlagsPrimitive) <> 0
            {
                if relation = RelationComparable"""
new = """        if (original_source.flags & TypeFlagsObject) <> 0
        {
            if false
            {
                if relation = RelationComparable"""''')

P['g24'] = ('''# The TYPE-PARAMETER / constraint fast path dropped. PREDICTION: UNGATED at stage
# 1 or nearly so — a type parameter reaching a comparison needs the generic
# machinery two chapters out; the reference calls it *super common* for a corpus
# this port cannot yet type.''',
'''old = """        if (source.flags & TypeFlagsTypeParameter) <> 0
        {
            let constraint this.get_constraint_of_type_parameter(source)
            if constraint <> null
            {
                if (constraint as ref[Type]) = target
                    return true
            }
        }"""
new = """"""''')

P['g25'] = ('''# The NULLABLE-UNION trim dropped — the reference's *remove null and/or undefined
# from the target* fast path. PREDICTION: `var x: string | null = "a"` stops
# answering; whether the corpus has one at this depth is what the row measures.''',
'''old = """        if (source.flags & TypeFlagsDefinitelyNonNullable) <> 0
        {
            if (target.flags & TypeFlagsUnion) <> 0
            {"""
new = """        if (source.flags & TypeFlagsDefinitelyNonNullable) <> 0
        {
            if false
            {"""''')

P['g26'] = ('''# elaborate_error NOT CALLED, so the relation reports at the error node wherever
# the elaborator would have answered. PREDICTION: the two recursion arms of
# rel_elaborate.ts report at the DECLARATION instead of nothing changing — and
# since both currently report at exactly that node, this row may be UNGATED on the
# fixtures and move only where an elaborating arm would have stopped.''',
'''old = """        if this.elaborate_error(expr, source, target, relation)
        {
            this.record_relation(error_node, source, target, 0)
            return false
        }"""
new = """        if false
        {
            this.record_relation(error_node, source, target, 0)
            return false
        }"""''')

P['g27'] = ('''# The object-literal arm's PRIMITIVE-TARGET early-out dropped — elaborateObjectLiteral's
# own first line. PREDICTION: `var x: string = {}` becomes a row instead of a
# diagnostic. The narrowest statement of what keeps that population reportable.''',
'''old = """            if (target.flags & (TypeFlagsPrimitive | TypeFlagsNever)) <> 0
                return false
            this.record_unported("elaborate-object-literal", k)"""
new = """            this.record_unported("elaborate-object-literal", k)"""''')

P['g28'] = ('''# The DID-YOU-MEAN signature guard dropped, so an object source with call
# signatures reports at the error node where the reference reports at the
# EXPRESSION. PREDICTION: UNGATED at stage 1 with a named wall — a function
# expression's type does not reach this site today, because the contextual
# machinery in front of it stops first.''',
'''old = """        if (source.flags & TypeFlagsObject) <> 0
        {
            let calls this.get_signatures_of_type(source, SignatureKindCall)"""
new = """        if false
        {
            let calls this.get_signatures_of_type(source, SignatureKindCall)"""''')

P['g29'] = ('''# The MARK GUARD in report_error_results removed — a report is made even when
# something stopped inside the comparison. PREDICTION: invented lines and a RED
# diagcheck. The first half of the two-part safety argument this chapter rests on.''',
'''old = """        if this.unported_mark() <> mark
            return
        ; ★★★ THE ERROR TYPE IS THAT GUARD ONE LEVEL UP"""
new = """        ; ★★★ THE ERROR TYPE IS THAT GUARD ONE LEVEL UP"""''')

P['g30'] = ('''# The ERROR-TYPE GUARD removed. PREDICTION: two invented TS2322 lines at STAGE 2
# and, at stage 1, whatever the smaller corpus holds — this is the defect the slice
# shipped and then repaired, kept as a row so the reasoning that produced it stays
# refuted. `error_type` answers TRUE against everything except a `never` target.''',
'''old = """        if this.is_error_type(source)
        {
            this.record_unported("error-type-relation", target.flags)
            return
        }
        if this.is_error_type(target)
        {
            this.record_unported("error-type-relation", source.flags)
            return
        }"""
new = """"""''')

P['g31'] = ('''# The TS2719 fork's SYMBOL condition dropped, so the two names are printed for
# every failing comparison. PREDICTION: the object-source population goes quiet —
# type_to_string reports on an anonymous object type, so every `var x: string = {}`
# becomes a row. The row that says a printer is a wall as much as a chapter is.''',
'''old = """        var same_name false
        if source.symbol <> null
        {
            if target.symbol <> null
            {"""
new = """        var same_name false
        if true
        {
            if true
            {"""''')

P['g32'] = ('''# The FIRST mark check in checkTypeRelatedToAndOptionallyElaborate removed — the
# one that separates *answered false* from *could not answer* before the elaborator
# runs. PREDICTION: the relgate's COULD-NOT-ANSWER count collapses into
# NOT-RELATED, and diagcheck goes RED wherever the deeper guard does not catch it.''',
'''old = """        if this.unported_mark() <> mark
        {
            this.record_relation(error_node, source, target, 2)
            return false
        }
        if error_node = null"""
new = """        if error_node = null"""''')

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

control "g01 THE PREMISE (the variable declaration's call) reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the ASSIGNMENT OPERATOR's call reverted to its stop" $CHECKER "$PATCHDIR/g02.py"
control "g03 the PROPERTY ASSIGNMENT's call reverted to its stop" $CHECKER "$PATCHDIR/g03.py"
control "g04 the COMPOUND ASSIGNMENT's write-type rewrite dropped" $CHECKER "$PATCHDIR/g04.py"
control "g05 isSimpleTypeRelatedTo's t&Any arm dropped" $CHECKER "$PATCHDIR/g05.py"
control "g06 the s&Never arm dropped" $CHECKER "$PATCHDIR/g06.py"
control "g07 the WILDCARD disjunct dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 the t&Unknown arm dropped" $CHECKER "$PATCHDIR/g08.py"
control "g09 the t&Never arm (the one that answers FALSE) dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 the StringLike/String arm dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the NumberLike/Number arm dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the BigIntLike/BigInt arm dropped" $CHECKER "$PATCHDIR/g12.py"
control "g13 the BooleanLike/Boolean arm dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 the ESSymbolLike/ESSymbol arm dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 the UNDEFINED arm dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 the NULL arm dropped" $CHECKER "$PATCHDIR/g16.py"
control "g17 the Object/NonPrimitive arm dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 the assignable block's s&Any arm dropped" $CHECKER "$PATCHDIR/g18.py"
control "g19 the two ENUM stops removed" $CHECKER "$PATCHDIR/g19.py"
control "g20 the FRESH-LITERAL normalization dropped" $CHECKER "$PATCHDIR/g20.py"
control "g21 the IDENTITY test dropped from isTypeRelatedTo" $CHECKER "$PATCHDIR/g21.py"
control "g22 the STRUCTURED branch answers FALSE instead of stopping" $CHECKER "$PATCHDIR/g22.py"
control "g23 the OBJECT-SOURCE / PRIMITIVE-TARGET early branch removed" $CHECKER "$PATCHDIR/g23.py"
control "g24 the TYPE-PARAMETER constraint fast path dropped" $CHECKER "$PATCHDIR/g24.py"
control "g25 the NULLABLE-UNION trim dropped" $CHECKER "$PATCHDIR/g25.py"
control "g26 elaborate_error not called" $CHECKER "$PATCHDIR/g26.py"
control "g27 the object-literal arm's PRIMITIVE-TARGET early-out dropped" $CHECKER "$PATCHDIR/g27.py"
control "g28 the DID-YOU-MEAN signature guard dropped" $CHECKER "$PATCHDIR/g28.py"
control "g29 the MARK GUARD in report_error_results removed" $CHECKER "$PATCHDIR/g29.py"
control "g30 the ERROR-TYPE GUARD removed" $CHECKER "$PATCHDIR/g30.py"
control "g31 the TS2719 fork's SYMBOL condition dropped" $CHECKER "$PATCHDIR/g31.py"
control "g32 the FIRST mark check in checkTypeRelatedToAndOptionallyElaborate removed" $CHECKER "$PATCHDIR/g32.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
