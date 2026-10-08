#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice97.sh — the slice-97 battery: THE `this` EXPRESSION.
#
# ★★★ THE ROW THIS SLICE CLOSES IS SLICE 96'S OWN NEAR WALL.
# `check-this-expression 109` was 103 events over 41 units at stage 1 and 2 727
# events over 778 units at stage 2, and `this.x` is a property access whose
# RECEIVER stops one call earlier — which is the sentence slice 96 closed on.
# g01 is the premise that carries the whole row; g02 and g03 are the other two
# producers of the same tag and NEITHER can go red, which is the battery's first
# containment proof rather than a defect in it.
#
# ★★★ THE TENTH INSTRUMENT, AND THE ARGUMENT IS PropEvent's ONE CHAPTER ON. The T
# section is all-or-nothing per unit, so this chapter's product — *the type a `this`
# answers, in the container the normalisation loop settled on* — is invisible on
# every unit that still has any other wall, which at stage 1 is 1 489 of 1 503.
# `tscaly_types --this` prints `H <pos> <end> <containerkind> <arm> <typeid> <name>`
# per `this` expression the chapter ANSWERED. The two middle columns are what
# separates this chapter's independent halves: `container_kind` is the only product
# of get_this_container's two flags and of the arrow/computed-name loop, while `arm`
# says which of tryGetThisTypeAtEx's answering paths ran — a method WITH a `this`
# parameter and a method without one have the same container and different arms.
#
# ★★★ AND THE FINDING THE INSTRUMENT MADE BEFORE A SINGLE CONTROL RAN, WHICH IS
# THE OPPOSITE OF SLICE 96'S: over the 1 412 units of the tree the THISGATE reads
# **103 answered `this` expressions, and only 15 of them are this slice's own
# fixtures** — 88 come from the real corpus, over some forty units. The chapter
# answers AND the corpus feeds it. ★What does NOT follow is that slice 96's product
# grows: the PROPGATE moves 15 → 18 and every one of the three is a fixture, because
# `this` answers a class's `this` TYPE and getApparentType of that type stops at
# `get-type-with-this-argument`. **A chapter can answer for the corpus and still not
# unblock its successor, and only two instruments side by side say so.**
#
# ★★★ RUN EACH GATE ONCE BY HAND BEFORE TRUSTING A ROW — slice 96's finding three,
# paid there and applied here: this battery is again a copy, and the rename that
# matters is the one inside `thisgate`, not the one on the pin. The hand count that
# licenses the numbers above is `--this` over the tree, 103 against 103.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice97.sh 2>&1 | tee /tmp/battery97.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
BINDER=$PKG/0.1.1/tscaly/binder.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Eight files, all this slice's: the
# four class containers, the normalisation loop, the container-decided reports, the
# implicit-any report, the signature arm, the two type-query producers, the two
# walls, and the flow fork. THREE of the eight are containment proofs rather than
# measurements — container, typequery and the enum half of reports — and each says
# so in its own header.
PINFILES="
$FIX/thisexpr_class.ts
$FIX/thisexpr_container.ts
$FIX/thisexpr_reports.ts
$FIX/thisexpr_implicit.ts
$FIX/thisexpr_signature.ts
$FIX/thisexpr_typequery.ts
$FIX/thisexpr_stops.ts
$FIX/thisexpr_flow.ts
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

WORK=$(mktemp -d -t tscaly-ctl97)

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

# ★★★ THE THISPIN — slice 97's TENTH instrument; the argument is in ThisEvent's
# own header. `H <pos> <end> <containerkind> <arm> <typeid> <name>` per `this`
# expression the chapter ANSWERED, in the order the check reached them.
thispin_of() {
  local f
  for f in $PINFILES; do
    printf '%s	%s
' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --this "$f" 2>/dev/null | tr '
' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS THISGATE, and it is here beside the pin for slice 92's
# h08/h11/h25 reason: a fixture is written around the arm its author is thinking
# of, and the shape that distinguishes an arm is usually not that shape. ★★Unlike
# slice 96's propgate it reads 103 rather than the fixtures' 15, so the corpus is
# a live half of every row below and not a constant.
#
# ★ The units are dispatched in PARALLEL and each writes its own file, then the
# files are concatenated in a fixed order. A shared pipe would interleave and the
# checksum would move on its own — an instrument that disagrees with itself is
# worse than none.
#
# ★★ IT IS A COUNT, AN UNNAMED COUNT AND A CHECKSUM, so two breakages are told
# apart without a diff: a chapter that stops answering moves the COUNT, a printer
# that cannot name what the chapter built moves the UNNAMED column, and a wrong
# CONTAINER, a wrong ARM or a wrong type moves the CHECKSUM at both counts
# unchanged.
#
# ★ NUL-DELIMITED SINCE SLICE 101, AND THE FIX IS NOT COSMETIC: `xargs` splits on
# WHITESPACE, the stage-2 corpus holds one unit whose name contains a space, and
# from it onward the `-n 2` pairing shifts by one — which redirects the dumper's
# stdout INTO A CORPUS FILE. Invisible at stage 1, where no unit path has a space.
# See §3.5eu finding nine.
thisgate() {
  local i=0 u
  rm -rf "$WORK/tout" "$WORK/tpairs"; mkdir -p "$WORK/tout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/tout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/tpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --this "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/tpairs"
  find "$WORK/tout" -type f -print0 | xargs -0 cat > "$WORK/this.all"
  local n q
  n=$(grep -c '^H ' "$WORK/this.all")
  q=$(grep -c ' ?$' "$WORK/this.all")
  echo "$n $q $(cksum < "$WORK/this.all" | cut -d' ' -f1)"
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; THIS_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — seven instruments"
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
  thispin_of > "$WORK/base.this"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  THIS_BASE=$(thisgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the THISPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.this"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             thisgate  (answers unnamed checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $THIS_BASE"
}

control() {   # $1 = label, $2 = files, $3 = patch
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
  thispin_of > "$WORK/ctl.this"
  stop=$(stopgate)
  local this_g
  this_g=$(thisgate)
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
    echo "  diagpin   unmoved — all eight pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all eight fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all eight fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.this" "$WORK/ctl.this"; then
    echo "  thispin   unmoved — all eight fixtures answer the same containers, arms and types."
  else
    green "thispin   RED"
    diff "$WORK/base.this" "$WORK/ctl.this" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$this_g" = "$THIS_BASE" ]; then
    echo "  thisgate  unmoved — $this_g"
  else
    green "thisgate  MOVED   $THIS_BASE -> $this_g   (answers unnamed checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all seven, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL SEVEN AND NOTHING MOVED AT ALL."
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

P['g01'] = ('''# THE PREMISE (the dispatcher's ThisKeyword arm) reverted to the stop it was until
# this slice. PREDICTION: everything RED — DIAGPIN, TAGPIN, STOPPIN, THISPIN — with
# the THISGATE's count to ZERO and the stopgate's events back up. One of THREE
# producers of the tag, and the only one with an input.''',
'''old = """        if k = KindThisKeyword
            return this.check_this_expression(node)"""
new = """        if k = KindThisKeyword
        {
            this.record_unported("check-this-expression", k)
            return null
        }"""''')

P['g02'] = ('''# THE SECOND PRODUCER (checkIdentifier's isThisInTypeQuery line) reverted to its
# stop. PREDICTION: UNGATED ON ALL SEVEN, PREDICTED — `get-type-from-type-query-node`
# fires one call in front of it, so the producer has no input;
# thisexpr_typequery.ts is the fixture that says why, and the arrival detail says it
# from the other side (all 103 stage-1 arrivals carried 109, the ThisKeyword). A row
# that CANNOT go red, with its containment proof at its own line.''',
'''old = """        if Checker.is_this_in_type_query(node)
            return this.check_this_expression(node)"""
new = """        if Checker.is_this_in_type_query(node)
        {
            this.record_unported("check-this-expression", KindThisKeyword)
            return null
        }"""''')

P['g03'] = ('''# THE THIRD PRODUCER (checkQualifiedName's `this.X`-inside-a-typeof fork) reverted
# to its stop. PREDICTION: UNGATED for g02's reason and measured separately, because
# the two producers are held by the SAME stop and a reader who sees g02 green must
# be told the fork below it is untested for that reason and not a different one.''',
'''old = """            if AstNode.is_this_identifier(l)
            {
                set forked: true
                let tt this.check_this_expression(l)
                if tt = null
                    return null
                set lt: this.check_non_null_type(tt as ref[Type], l)
            }"""
new = """            if AstNode.is_this_identifier(l)
            {
                set forked: true
                this.record_unported("check-this-expression", AstNode.kind_of(l))
                return null
            }"""''')

P['g04'] = ('''# get_this_container IGNORES include_arrow_functions and always returns at an arrow.
# PREDICTION: it moves something OUTSIDE this chapter and nothing inside it. The
# walk has three callers and only this slice's passes `true` at the head; the flag
# was FROZEN at that value until this slice, and getDeclaringConstructor is the call
# site the freeze had wrong. So this row is the defect, replayed.''',
'''old = """                    if k = KindArrowFunction
                    {
                        if include_arrow_functions
                            return node
                    }"""
new = """                    if k = KindArrowFunction
                        return node"""''')

P['g05'] = ('''# get_this_container IGNORES include_class_computed_property_name, i.e. the arm
# that was missing entirely before this slice. PREDICTION: ungated with an
# argument — a computed property name in a class stops at `get-late-bound-symbol`
# one chapter in front of the container question, which thisexpr_container.ts is
# the proof of.''',
'''old = """                if include_class_computed_property_name
                {
                    if Parser.is_class_like_node(g)
                        return node
                }"""
new = """                if false
                {
                    if Parser.is_class_like_node(g)
                        return node
                }"""''')

P['g06'] = ('''# get_this_container skips ONE level at a computed property name instead of two
# (`node.Parent` rather than `node.Parent.Parent`). PREDICTION: it can only move
# something outside this chapter, for g05's reason — and it is here because the walk
# is now shared and a shared walk's breakage must be visible from the slice that
# generalised it.''',
'''old = """                let g AstNode.parent_node_of(p)
                if include_class_computed_property_name"""
new = """                let g: ref[AstNode]? p
                if include_class_computed_property_name"""''')

P['g07'] = ('''# THE ARROW HOP of the normalisation loop removed. PREDICTION: ungated, and it is a
# CONTAINMENT PROOF rather than a hole: an arrow's body is checked deferred
# (`check-function-expression-or-object-literal-method`), so no `this` in this
# corpus reaches the loop with an arrow container. The hop lands with that chapter.''',
'''old = """            if AstNode.kind_of(container) = KindArrowFunction
            {
                var include_computed true
                if this_in_computed_property_name
                    set include_computed: false
                let up Binder.get_this_container(container, false, include_computed)
                if up = null
                {
                    this.record_unported("this-container", AstNode.kind_of(container))
                    return null
                }
                set container: up as ref[AstNode]
                set captured_by_arrow_function: true
            }"""
new = """            if false
            {
                set captured_by_arrow_function: true
            }"""''')

P['g08'] = ('''# THE COMPUTED-NAME HOP removed, which also removes the only producer of TS2465.
# PREDICTION: ungated for g05's reason — the class computed name stops one chapter
# earlier and the object-literal one at `check-object-literal`. The row prices the
# report rather than closing it.''',
'''old = """            if AstNode.kind_of(container) = KindComputedPropertyName
            {
                var include_arrows true
                if captured_by_arrow_function
                    set include_arrows: false
                let up Binder.get_this_container(container, include_arrows, false)
                if up = null
                {
                    this.record_unported("this-container", AstNode.kind_of(container))
                    return null
                }
                set container: up as ref[AstNode]
                set this_in_computed_property_name: true
                set normalising: true
            }"""
new = """            if false
                set normalising: true"""''')

P['g09'] = ('''# THE MODULE-BODY REPORT (TS2331) removed. PREDICTION: DIAGPIN RED on
# thisexpr_reports.ts with diagcheck UNGATED AT A LOSS — a subsequence cannot see a
# diagnostic we stop printing, which is the half of this battery only the pin
# covers.''',
'''old = """            if ck = KindModuleDeclaration
                this.error_on_node(node, DiagX_this_cannot_be_referenced_in_a_module_or_namespace_body)"""
new = """            if false
                this.error_on_node(node, DiagX_this_cannot_be_referenced_in_a_module_or_namespace_body)"""''')

P['g10'] = ('''# THE MODULE-BODY REPORT made unconditional — every answered `this` reports TS2331.
# PREDICTION: diagcheck RED, because inventing is the direction a subsequence CAN
# see. It is g09's other half and the row that says the container test is the whole
# of that report.''',
'''old = """            if ck = KindModuleDeclaration
                this.error_on_node(node, DiagX_this_cannot_be_referenced_in_a_module_or_namespace_body)"""
new = """            if true
                this.error_on_node(node, DiagX_this_cannot_be_referenced_in_a_module_or_namespace_body)"""''')

P['g11'] = ('''# THE ENUM-BODY REPORT (TS2332) removed. PREDICTION: ungated with a PROOF — an enum
# member's initializer is reached through computeEnumMemberValues, which stops one
# chapter in front of the expression, so the arm is written and unreachable. The
# enum half of thisexpr_reports.ts is the fixture that shows the reference printing
# TS2332 where we print nothing.''',
'''old = """            if ck = KindEnumDeclaration
                this.error_on_node(node, DiagX_this_cannot_be_referenced_in_current_location)"""
new = """            if false
                this.error_on_node(node, DiagX_this_cannot_be_referenced_in_current_location)"""''')

P['g12'] = ('''# THE COMPUTED-NAME REPORT (TS2465) removed. PREDICTION: ungated for g08's reason,
# and measured separately from it because a reader who sees g08 green must be told
# the report below it is untested for the same reason.''',
'''old = """        if this_in_computed_property_name
            this.error_on_node(node, DiagX_this_cannot_be_referenced_in_a_computed_property_name)"""
new = """        if false
            this.error_on_node(node, DiagX_this_cannot_be_referenced_in_a_computed_property_name)"""''')

P['g13'] = ('''# TS2683 removed — the one report of this chapter that needs the TYPE and needs it
# to be ABSENT. PREDICTION: DIAGPIN RED on thisexpr_implicit.ts and
# thisexpr_reports.ts, diagcheck ungated AT A LOSS.''',
'''old = """            if t = null
                this.error_on_node(node, DiagX_this_implicitly_has_type_any_because_it_does_not_have_a_type_annotation)"""
new = """            if false
                this.error_on_node(node, DiagX_this_implicitly_has_type_any_because_it_does_not_have_a_type_annotation)"""''')

P['g14'] = ('''# noImplicitThis forced FALSE — the option read rather than the branch. PREDICTION:
# exactly g13's verdict, and that is the point: the option is TRUE under this
# harness, so reading "the harness sets no options" as "the option is off" would
# have silently deleted this chapter's only type-dependent report. It is the fourth
# strict-family option and the row that prices it.''',
'''old = """    function no_implicit_this() returns bool
        true"""
new = """    function no_implicit_this() returns bool
        false"""''')

P['g15'] = ('''# TS2683 made unconditional — reported even where the chapter ANSWERS a type.
# PREDICTION: diagcheck RED. g13's other half, and the direction a subsequence sees.''',
'''old = """            if t = null
                this.error_on_node(node, DiagX_this_implicitly_has_type_any_because_it_does_not_have_a_type_annotation)"""
new = """            if true
                this.error_on_node(node, DiagX_this_implicitly_has_type_any_because_it_does_not_have_a_type_annotation)"""''')

P['g16'] = ('''# checkThisBeforeSuper's extends-clause guard removed, so the derived-class check
# runs for every constructor. PREDICTION: STOPPIN/STOPGATE MOVED —
# classDeclarationExtendsNull is asked for classes with no base too, and its first
# two calls answer while the third returns at its no-base arm, so what moves is
# where the walk goes and not what it reports.''',
'''old = """        if Checker.get_extends_heritage_clause_element(cc) = null
            return
        let mark this.unported_mark()
        let extends_null this.class_declaration_extends_null(cc)"""
new = """        if false
            return
        let mark this.unported_mark()
        let extends_null this.class_declaration_extends_null(cc)"""''')

P['g17'] = ('''# checkThisBeforeSuper's extends_null test INVERTED. PREDICTION: ungated with a
# PROOF — the line below it is unreachable, because classDeclarationExtendsNull
# reports `is-constructor-type` for exactly the class that reaches this test. The
# row is the measured form of the sentence at check_this_before_super's own head.''',
'''old = """        if extends_null
            return
        this.record_unported("is-post-super-flow-node", KindConstructor)"""
new = """        if extends_null = false
            return
        this.record_unported("is-post-super-flow-node", KindConstructor)"""''')

P['g18'] = ('''# checkThisBeforeSuper never called at all. PREDICTION: STOPPIN/STOPGATE MOVED on
# the fixtures with a constructor — a `this` in a derived constructor carries
# `is-constructor-type` today, and this row is what says that tag is THIS call's.''',
'''old = """        if AstNode.kind_of(container) = KindConstructor
            this.check_this_before_super(node, container, DiagX_super_must_be_called_before_accessing_this_in_the_constructor_of_a_derived_class)"""
new = """        if false
            this.check_this_before_super(node, container, DiagX_super_must_be_called_before_accessing_this_in_the_constructor_of_a_derived_class)"""''')

P['g19'] = ('''# legacy_decorators forced TRUE, which arms checkThisInStaticClassField-
# InitializerInDecoratedClass. PREDICTION: ungated, and it is a HOLE named rather
# than a verdict: no fixture has a decorated class with a static property
# initializer, so the arm behind the option has no input even with the option on.''',
'''old = """        set c.legacy_decorators: false"""
new = """        set c.legacy_decorators: true"""''')

P['g20'] = ('''# the static-property guard of that function dropped, so ANY property declaration
# container reaches the decorator test. PREDICTION: ungated for g19's reason —
# legacy_decorators is false, so the line below the guard is dead either way. The
# two rows together price the option and its input separately.''',
'''old = """        if b.has_syntactic_modifier(container, ModifierFlagsStatic) = false
            return
        if legacy_decorators = false
            return"""
new = """        if false
            return
        if legacy_decorators = false
            return"""''')

P['g21'] = ('''# tryGetThisTypeAtEx's SIGNATURE arm never runs. PREDICTION: THISPIN RED on
# thisexpr_signature.ts and thisexpr_flow.ts with the arm column 1 → 3 or 0, and the
# THISGATE's checksum moving at an unchanged count — a `this` parameter answered as
# a class `this` is a well-formed WRONG answer, which is the shape the arm column
# was added for.''',
'''old = """            if ask
            {"""
new = """            if false
            {"""''')

P['g22'] = ('''# isInParameterInitializerBeforeContainingFunction always answers TRUE, so the
# signature arm is asked only where a `this` parameter is declared. PREDICTION:
# THISPIN RED wherever a method answers through its signature without one — the row
# that separates the guard from the arm it guards.''',
'''old = """            var ask true
            if Checker.is_in_parameter_initializer_before_containing_function(node)"""
new = """            var ask true
            if true"""''')

P['g23'] = ('''# the getContextualThisParameterType fallback removed. PREDICTION: ungated with an
# argument — every container in these fixtures either declares a `this` parameter or
# is a class member, and the contextual reading stops at `get-contextual-signature`
# one call in. The row prices a fallback that is a wall in disguise.''',
'''old = """                    set this_type: this.get_contextual_this_parameter_type(c)
                    if this.unported_mark() <> mark
                        return null
                    set arm: 2"""
new = """                    if false
                        set arm: 2"""''')

P['g24'] = ('''# tryGetThisTypeAtEx's CLASS arm never runs. PREDICTION: THISPIN RED almost
# everywhere and the THISGATE's count DOWN — 89 of the corpus's 103 answers are arm
# 3. The second premise of this chapter: what `this` means is a class's `this` type,
# and everything else is a minority.''',
'''old = """            if Parser.is_class_like_node(parent as ref[AstNode])
            {"""
new = """            if false
            {"""''')

P['g25'] = ('''# the STATIC test ignored, so a static member answers the class's `this` type
# instead of the class's own type. PREDICTION: THISPIN RED in the ARM and NAME
# columns at an unchanged count — `typeof C` becomes `C`, three rows corpus-wide.
# A count-only gate cannot see this and the checksum can.''',
'''old = """                if b.has_syntactic_modifier(c, ModifierFlagsStatic)
                {
                    set out_arm: 4"""
new = """                if false
                {
                    set out_arm: 4"""''')

P['g26'] = ('''# the FLOW WALK dropped from both answering paths — the declared type is returned
# directly. PREDICTION: THISPIN RED on thisexpr_flow.ts and the THISGATE's checksum
# moving; this is the row that says getFlowTypeOfReference, the two-argument entry
# slice 93 left for its first caller, is load-bearing here and not a formality.''',
'''old = """    function get_flow_type_of_reference(this, reference: ref[AstNode], t: ref[Type]) returns ref[Type]?
        this.get_flow_type_of_reference_ex(reference, t, t, null, null)"""
new = """    function get_flow_type_of_reference(this, reference: ref[AstNode], t: ref[Type]) returns ref[Type]?
        t"""''')

P['g27'] = ('''# the SOURCE-FILE arm answers null instead of `undefined` for a module.
# PREDICTION: THISPIN RED on thisexpr_reports.ts (arm 5 → 0, `undefined` → `any`)
# AND diagcheck RED — a module-level `this` with no type INVENTS a TS2683, which is
# the direction a subsequence sees. One patch, two instruments, opposite halves.''',
'''old = """            if b.is_external_module_of()
            {
                set out_arm: 5
                return undefined_type
            }"""
new = """            if false
            {
                set out_arm: 5
                return undefined_type
            }"""''')

P['g28'] = ('''# the globalThis STOP removed, so a `this` at the top level of a SCRIPT falls
# through to nothing. PREDICTION: STOPPIN RED on thisexpr_stops.ts and diagcheck
# RED — without the stop the chapter reports TS2683 where the reference answers the
# globals table's type. The row that says a stop is an ANSWER this port must not
# give (§3.11).''',
'''old = """                this.record_unported("global-this-type", KindSourceFile)
                return null"""
new = """                if false
                    return null"""''')

P['g29'] = ('''# the `any` FALLBACK removed — a chapter that answers nothing returns nothing.
# PREDICTION: THISGATE's count DOWN by the seven arm-0 rows and the STOPGATE
# unmoved, because returning null without a stop is exactly the silent shape this
# port's walls exist to prevent. The row prices the reference's own last two lines.''',
'''old = """        var answer t
        if answer = null
            set answer: any_type"""
new = """        var answer t
        if answer = null
            return null"""''')

P['g30'] = ('''# the container computed by the normalisation loop is NOT passed on, so
# tryGetThisTypeAtEx recomputes it with `(false, false)`. PREDICTION: ungated with
# an argument — the loop has no input on this corpus (g07, g08), so the recomputed
# container equals the passed one everywhere here. The row is the price of the
# parameter, and it is the one row of this battery whose green is a claim about the
# NEXT slice.''',
'''old = """        let t this.try_get_this_type_at_ex(node, true, container, &arm)"""
new = """        let t this.try_get_this_type_at_ex(node, true, null, &arm)"""''')

for k, (doc, body) in P.items():
    with open(os.path.join(D, k + '.py'), 'w') as f:
        f.write(doc + '\n')
        f.write('''import sys
''')
        f.write(body + '\n')
        f.write('''
path = sys.argv[1]
s = open(path).read()
if s.count(old) != 1:
    sys.stderr.write("anchor count %d for %s\\n" % (s.count(old), path))
    sys.exit(1)
open(path, 'w').write(s.replace(old, new))
''')
MKPATCHES

baseline

control "g01 THE PREMISE (the dispatcher's ThisKeyword arm) reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 THE SECOND PRODUCER (checkIdentifier's isThisInTypeQuery) reverted to its stop" $CHECKER "$PATCHDIR/g02.py"
control "g03 THE THIRD PRODUCER (checkQualifiedName's this-in-typeof fork) reverted to its stop" $CHECKER "$PATCHDIR/g03.py"
control "g04 get_this_container ignores include_arrow_functions" $BINDER "$PATCHDIR/g04.py"
control "g05 get_this_container ignores include_class_computed_property_name" $BINDER "$PATCHDIR/g05.py"
control "g06 get_this_container skips ONE level at a computed property name" $BINDER "$PATCHDIR/g06.py"
control "g07 the ARROW HOP of the normalisation loop removed" $CHECKER "$PATCHDIR/g07.py"
control "g08 the COMPUTED-NAME HOP removed" $CHECKER "$PATCHDIR/g08.py"
control "g09 the MODULE-BODY report removed" $CHECKER "$PATCHDIR/g09.py"
control "g10 the MODULE-BODY report made unconditional" $CHECKER "$PATCHDIR/g10.py"
control "g11 the ENUM-BODY report removed" $CHECKER "$PATCHDIR/g11.py"
control "g12 the COMPUTED-NAME report removed" $CHECKER "$PATCHDIR/g12.py"
control "g13 TS2683 removed" $CHECKER "$PATCHDIR/g13.py"
control "g14 noImplicitThis forced FALSE" $CHECKER "$PATCHDIR/g14.py"
control "g15 TS2683 made unconditional" $CHECKER "$PATCHDIR/g15.py"
control "g16 checkThisBeforeSuper's extends-clause guard removed" $CHECKER "$PATCHDIR/g16.py"
control "g17 checkThisBeforeSuper's extends_null test INVERTED" $CHECKER "$PATCHDIR/g17.py"
control "g18 checkThisBeforeSuper never called" $CHECKER "$PATCHDIR/g18.py"
control "g19 legacy_decorators forced TRUE" $CHECKER "$PATCHDIR/g19.py"
control "g20 the static-property guard of the decorated-class check dropped" $CHECKER "$PATCHDIR/g20.py"
control "g21 tryGetThisTypeAtEx's SIGNATURE arm never runs" $CHECKER "$PATCHDIR/g21.py"
control "g22 isInParameterInitializerBeforeContainingFunction always TRUE" $CHECKER "$PATCHDIR/g22.py"
control "g23 the getContextualThisParameterType fallback removed" $CHECKER "$PATCHDIR/g23.py"
control "g24 tryGetThisTypeAtEx's CLASS arm never runs" $CHECKER "$PATCHDIR/g24.py"
control "g25 the STATIC test ignored" $CHECKER "$PATCHDIR/g25.py"
control "g26 the FLOW WALK dropped from both answering paths" $CHECKER "$PATCHDIR/g26.py"
control "g27 the SOURCE-FILE arm answers null instead of undefined" $CHECKER "$PATCHDIR/g27.py"
control "g28 the globalThis STOP removed" $CHECKER "$PATCHDIR/g28.py"
control "g29 the `any` FALLBACK removed" $CHECKER "$PATCHDIR/g29.py"
control "g30 the computed container is not passed to tryGetThisTypeAtEx" $CHECKER "$PATCHDIR/g30.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
