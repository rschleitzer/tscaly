#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice61.sh — the slice-61 battery: the TYPE-NODE arms of
# checkSourceElement, the half of the switch that slice 60's two recursions
# started feeding.
#
# ★★★ TWENTY-SEVEN ROWS OVER NINETEEN `case` LABELS, AND THE RATIO IS THE SLICE'S
# SHAPE RATHER THAN A BUDGET. Sixteen of the nineteen cases are a WALK with at most
# a grammar check in front of it, so most of what this slice can get wrong is not a
# wrong report but a MISSING recursion — and a missing recursion is silent in both
# instruments unless something reports at the bottom of it. Five rows (g01–g05)
# therefore aim at the recursions and read the walk-closure fixture, whose whole
# design is a diagnostic six arms down.
#
# ★★★ THE THREE ROWS THAT MATTER MOST ARE THE ONES THAT INVENT A DIAGNOSTIC, and
# each names a reading a careful port would plausibly have taken:
#
#   g13  checkTupleType SKIPS the variadic element instead of BREAKING. The
#        reference resolves `...R`, finds it array-like, marks it Rest and reports
#        TS1266 on the optional element after it; a port that skips what it cannot
#        classify carries seenRestElement=false forward and reports TS1257 on the
#        element after THAT — a line the reference does not have. This is the row
#        that says why the break is in the code.
#   g19  checkInferType asks whether its own PARENT is the conditional's extends
#        type instead of walking up. `string extends (infer W) ? W : never` is legal
#        and the parenthesized type is what a non-walking reading trips on.
#   g23  the JSDoc-dot scan compares the token against `<` instead of `.`. Every
#        ordinary `Box<number>` in the corpus then reports TS8020.
#
# ★★ TWO INSTRUMENTS. diagcheck gates the reports; a PIN over the fourteen
# fixtures' unported TAGS gates the arms that produce none — the five recursions,
# the signature wiring and the index signature's newly reached report. Slice 56's
# rule holds for every fixture in the pin: ONE shape per file, because
# record_unported keeps the FIRST report.
#
# ★★★ AND ONE ROW CAME BACK UNGATED FOR TWO DIFFERENT REASONS STACKED, WHICH IS
# WHERE g26, g27 AND THE ONE .js FIXTURE COME FROM. g24 removes
# checkJSDocTypeIsInJsFile's JS-file guard and moves nothing at all. Reason one is a
# gate one step earlier — in a JavaScript file a JSDoc type reaches the tree only
# through the reparser, hung on a declaration that carries NodeFlagsHasJSDoc, and
# check_source_element_worker reports `check-jsdoc-comments` and returns before the
# switch: §3.5v row 2, UNREACHABLE, and no fixture can change it. So g26 lifts that
# gate as a PREMISE and g27 stacks the guard removal on top — and the pair STILL
# moved nothing on the first run, which is reason two and a different row of the
# same table: §3.5v row 1, UNCOVERED. No unit of the corpus puts a `*` or a JSDoc
# type literal in a type slot the walk reaches, and the answer to that row is a
# fixture. checker_jsdoc_type_in_js.js is it, and it is silent on both sides in the
# baseline and TS8020 under g27 — which is what a guard being load-bearing looks
# like when it is measured rather than argued.
#
# ★ A row that only REMOVES a diagnostic is ungated on diagcheck by construction —
# its relation is a SUBSEQUENCE — and is a measurement when the falling count is
# printed. Seven rows are of that kind and each carries the number that is its
# whole content.
#
# ★ ONE FILE IS PATCHED, checker.scaly. Every patch is dry-run against a copy of
# the tree before the first build is spent (slice 57's lesson), and the restore is
# proven with `cmp` and survives a kill (slice 58's).
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice61.sh 2>&1 | tee /tmp/battery61.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads — all fifteen of this slice's. Five of them produce
# no diagnostic of their own and exist for the tag alone; the other nine carry both,
# and the pin is what catches a row that leaves the report standing while breaking
# the walk underneath it. One shape per file (slice 56's *a fixture that cannot be
# first is not a witness*).
TAGFILES="
$FIX/checker_type_operator_unique.ts
$FIX/checker_type_operator_readonly.ts
$FIX/checker_tuple_ordering.ts
$FIX/checker_tuple_variadic_stop.ts
$FIX/checker_named_tuple_member.ts
$FIX/checker_mapped_type_members.ts
$FIX/checker_infer_type_placement.ts
$FIX/checker_jsdoc_type_in_ts.ts
$FIX/checker_type_predicate_position.ts
$FIX/checker_type_reference_jsdoc_dot.ts
$FIX/checker_type_literal_members.ts
$FIX/checker_type_walk_closure.ts
$FIX/checker_index_signature_reachable.ts
$FIX/checker_type_node_stops.ts
$FIX/checker_jsdoc_type_in_js.js
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl61)

PATCHED_FILE=""
PATCHED_ORIG=""
cleanup() {
  if [ -n "$PATCHED_FILE" ] && [ -f "$PATCHED_ORIG" ]; then
    cp "$PATCHED_ORIG" "$PATCHED_FILE"
    red "INTERRUPTED — $PATCHED_FILE restored from the row that was running."
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

tags_of() {
  local f
  for f in $TAGFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

baseline() {
  echo "################################################################"
  bold "BASELINE — both instruments"
  if ! build_diag_bin; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  sed -n '/^diagcheck/,$p' "$WORK/base.diag" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  echo
  echo "  the PIN — the fixtures' unported tags on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the pin would be comparing two empties."
    exit 2
  fi
  echo
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

control() {   # $1 = label, $2 = file, $3 = python patch file, $4 = optional tag file to diff against
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  PATCHED_ORIG=$WORK/orig
  PATCHED_FILE=$2
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    PATCHED_FILE=""
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
    PATCHED_FILE=""
    return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILE=""
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  # ★ The comparison PARTNER is a parameter. No row of THIS battery stacks two
  # patches, so every pin is read against the unpatched tree; it is kept because
  # slice 60 needed it and the next stacking slice will.
  local against=${4:-$WORK/base.tags}
  local againstname="the baseline"
  [ "$against" = "$WORK/base.tags" ] || againstname="$(basename "$against" .tags)"
  if cmp -s "$against" "$WORK/ctl.tags"; then
    echo "  pin       unmoved against $againstname — all fifteen fixtures answer the same tag."
  else
    green "pin       RED against $againstname"
    diff "$against" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  cp "$WORK/ctl.tags" "$WORK/last.tags"
  if [ "$rc" = 0 ] && cmp -s "$against" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
      echo "  A control which REMOVES a diagnostic is ungated on diagcheck by"
      echo "  construction (its header), and the falling count is then the row."
    else
      red "UNGATED on BOTH INSTRUMENTS AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

# ── the patches ─────────────────────────────────────────────────────────────
#
# Written first, ALL of them, so the dry run below can apply every one against a
# copy of the tree before a single build is spent.

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkArrayType's RECURSION REMOVED — the arm reduced to nothing, which is
# what an arm whose body is one line looks like when it is forgotten. It is the
# cheapest of the five walk rows and the one whose absence is hardest to see:
# `T[]` still walks in the WALK dump (that is a different traversal), and every
# yardstick counter stays put. Only a diagnostic at the bottom of an array type
# moves, which is what checker_type_walk_closure.ts is.
old = """    procedure check_array_type(this, node: pointer[AstNode])
        this.check_source_element(AstNode.array_element_type_of(node))"""
new = """    procedure check_array_type(this, node: pointer[AstNode])
        this.check_source_element(null)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE THREE ARMS WHOSE BODY IS A BARE ForEachChild — ParenthesizedType,
# OptionalType and RestType — MADE NO-OPS. They are the arms most easily left out,
# because the reference writes them as one shared `case` with no function of its
# own and they look like the twelve kinds that have no case at all. The
# difference between the two is exactly this row.
old = """    procedure check_each_child_source_element(this, node: pointer[AstNode])
    {
        let count AstNode.child_count(node)"""
new = """    procedure check_each_child_source_element(this, node: pointer[AstNode])
    {
        let count 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkTypeOperator's RECURSION REMOVED, its grammar check left in place. The
# pair with g01: two one-line arms, and this one still reports TS1354 and TS1335
# while nothing under `keyof`/`readonly`/`unique` is checked — a port that is loud
# and blind at once, which is the shape a pin exists to catch.
old = """        this.check_grammar_type_operator_node(node)
        this.check_source_element(AstNode.type_operator_inner_of(node))"""
new = """        this.check_grammar_type_operator_node(node)
        this.check_source_element(AstNode.type_operator_inner_of(null))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkTupleType's ELEMENT RECURSION REMOVED, the ordering loop left in place.
# The reference's checkSourceElements(elements) is BELOW the loop and unconditional;
# dropping it leaves every tuple's ordering reports intact and hides everything
# inside its elements.
old = """        this.check_source_elements(elements)
        this.record_unported("get-type-from-type-node", KindTupleType)"""
new = """        this.record_unported("get-type-from-type-node", KindTupleType)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkTypeLiteral's MEMBERS WALK REMOVED — one line, and it is the line that
# made five signature kinds and two member kinds reachable at once. TS1098 and
# TS2300 of checker_type_literal_members.ts go with it, and so does the index
# signature's report, whose fixture falls back to the type literal's own stop.
old = """        this.check_source_elements(AstNode.type_literal_members_of(node))"""
new = """        this.check_source_elements(null)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE `unique` OPERAND TEST INVERTED — `unique symbol` reports TS1005 and
# `unique string` does not. The most direct statement that the arm's first question
# is *is the operand the `symbol` keyword*, and it turns three of the fixture's four
# reports into one at the wrong place.
old = """            if Checker.kind_or_unknown(inner_type) <> KindSymbolKeyword
                return this.grammar_error_on_node(inner_type, DiagX_0_expected)"""
new = """            if Checker.kind_or_unknown(inner_type) = KindSymbolKeyword
                return this.grammar_error_on_node(inner_type, DiagX_0_expected)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ WalkUpParenthesizedTypes' CLIMB REMOVED — the operator's immediate parent is
# read instead. `declare const parenthesized: (unique symbol)` then lands on the
# ParenthesizedType, falls through every named arm and reports TS1335, *unique
# symbol types are not allowed here*, on a declaration the reference accepts. It is
# the row the parenthesized line of the fixture exists for, and it is the half of
# the function whose name misleads: the walk goes UP, not into the parentheses.
old = """            var parent AstNode.parent_node_of(node)
            while Checker.kind_or_unknown(parent) = KindParenthesizedType
                set parent: AstNode.parent_node_of(parent)"""
new = """            var parent AstNode.parent_node_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE CONST FLAG READ FROM THE DECLARATION RATHER THAN FROM ITS LIST.
# NodeFlagsConst lives on the VariableDeclarationList — `const` is a property of the
# list, not of one declarator — so reading it off the declaration answers false for
# every declaration there is and TS1332 fires on the legal `declare const legal`.
# An off-by-one-parent that a fixture without a legal case could never catch.
old = """                if (AstNode.flags_of(AstNode.parent_node_of(parent)) & NodeFlagsConst) = 0"""
new = """                if (AstNode.flags_of(parent) & NodeFlagsConst) = 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ TS1333's SPAN MOVED TO THE NAME. The reference reports the binding-name case on
# the OPERATOR NODE (`unique symbol` entire) and the const case on the declaration's
# NAME, two lines apart in the same arm; this is the confusion between them. The
# codes and the counts are unchanged and only the span moves, so diagcheck is the
# only thing that can see it.
old = """                    return this.grammar_error_on_node(node, DiagX_unique_symbol_types_may_not_be_used_on_a_variable_declaration_with_a_binding_name)"""
new = """                    return this.grammar_error_on_node(AstNode.name_of(parent), DiagX_unique_symbol_types_may_not_be_used_on_a_variable_declaration_with_a_binding_name)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE BINDING-NAME TEST DROPPED, so `declare const [destructured]: unique symbol`
# reports the CONST message instead (it is a const, so nothing at all). One
# diagnostic disappears; the row is ungated on diagcheck by construction and its
# content is the number.
old = """                if Checker.kind_or_unknown(AstNode.name_of(parent)) <> KindIdentifier
                    return this.grammar_error_on_node(node, DiagX_unique_symbol_types_may_not_be_used_on_a_variable_declaration_with_a_binding_name)"""
new = """                if false
                    return this.grammar_error_on_node(node, DiagX_unique_symbol_types_may_not_be_used_on_a_variable_declaration_with_a_binding_name)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ readonly's TUPLE ALLOWANCE REMOVED. `readonly [string, number]` then reports
# TS1354, which the reference accepts — the operand list is ArrayType OR TupleType
# and a port that remembered only the array half looks right on every corpus line
# that spells `readonly T[]`.
old = """            if ik = KindArrayType
                return false
            if ik = KindTupleType
                return false"""
new = """            if ik = KindArrayType
                return false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ readonly REPORTED ON THE WHOLE OPERATOR NODE rather than on its first token.
# grammarErrorOnFirstToken spans the `readonly` keyword alone; grammar_error_on_node
# spans `readonly string` entire. Same code, same count, different span — the
# distinction the two reporters exist for.
old = """            return this.grammar_error_on_first_token(node, DiagX_readonly_type_modifier_is_only_permitted_on_array_and_tuple_literal_types)"""
new = """            return this.grammar_error_on_node(node, DiagX_readonly_type_modifier_is_only_permitted_on_array_and_tuple_literal_types)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE ROW THIS SLICE'S HARDEST DECISION EXISTS FOR: checkTupleType SKIPS the
# variadic element instead of BREAKING at it. The reference resolves `...R`, finds
# it array-like, marks the element Rest and reports TS1266 on the optional element
# that follows; a port that merely skips what it cannot classify carries
# seenRestElement=false into the next round, misses TS1266 and then reports TS1257
# on `number` — a diagnostic the reference does not have, which is the one thing
# diagcheck can fail on. checker_tuple_variadic_stop.ts is the witness and this row
# is the proof that the witness is needed.
old = """            if (flags & ElementFlagsVariadic) <> 0
            {
                this.record_unported("get-type-from-type-node", AstNode.kind_of(e))
                break
            }"""
new = """            if (flags & ElementFlagsVariadic) <> 0
            {
                this.record_unported("get-type-from-type-node", AstNode.kind_of(e))
                set i: i + 1
                continue
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ getArrayElementTypeNode FORCED TO ANSWER NULL, so every `...T` is VARIADIC and
# no tuple element is ever REST. It is the row that prices the syntactic probe: with
# it gone the ordering loop stops at the first spread in every tuple the corpus has,
# and TS1265 and TS1266 disappear. Ungated on diagcheck by construction; the falling
# count is the measurement.
old = """    function array_element_type_node_of(n: pointer[AstNode]) returns pointer[AstNode]
    {
        let k Checker.kind_or_unknown(n)"""
new = """    function array_element_type_node_of(n: pointer[AstNode]) returns pointer[AstNode]
    {
        let k KindUnknown"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ TS1257 REPORTED ON THE TUPLE rather than on the offending element. All three
# ordering reports are `grammarErrorOnNode(e, …)` — on the ELEMENT — and a port that
# reported the container would look right in a count and wrong in every span.
old = """                        if seen_optional_element
                        {
                            this.grammar_error_on_node(e, DiagA_required_element_cannot_follow_an_optional_element)"""
new = """                        if seen_optional_element
                        {
                            this.grammar_error_on_node(node, DiagA_required_element_cannot_follow_an_optional_element)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkNamedTupleMember's TWO TYPE REPORTS MOVED TO THE MEMBER. TS5085 spans the
# member and TS5086/TS5087 span its TYPE; reporting all three at the member is the
# reading a reader of the message text would take (all three are about the member),
# and it is wrong twice.
old = """        if tk = KindOptionalType
            this.grammar_error_on_node(type_node, DiagA_labeled_tuple_element_is_declared_as_optional_with_a_question_mark_after_the_name_and_before_the_colon_rather_than_after_the_type)
        if tk = KindRestType
            this.grammar_error_on_node(type_node, DiagA_labeled_tuple_element_is_declared_as_rest_with_a_before_the_name_rather_than_before_the_type)"""
new = """        if tk = KindOptionalType
            this.grammar_error_on_node(node, DiagA_labeled_tuple_element_is_declared_as_optional_with_a_question_mark_after_the_name_and_before_the_colon_rather_than_after_the_type)
        if tk = KindRestType
            this.grammar_error_on_node(node, DiagA_labeled_tuple_element_is_declared_as_rest_with_a_before_the_name_rather_than_before_the_type)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ checkGrammarMappedType's CALL REMOVED. TS7061 disappears; ungated on diagcheck
# by construction and a measurement through the count. Its partner is g18, which
# keeps the call and moves the span — together they say that the report is one per
# mapped type and that it names the FIRST member.
old = """        this.check_grammar_mapped_type(node)
        this.check_source_element(AstNode.mapped_type_parameter_of(node))"""
new = """        this.check_source_element(AstNode.mapped_type_parameter_of(node))"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ TS7061 ON THE LAST MEMBER instead of the first. A mapped type's member list is
# the parser's recovery slot and the reference reports once, on member zero, however
# many there are — which a fixture with one member could not distinguish from *once
# per member* or from *on the last*. checker_mapped_type_members.ts carries two.
old = """        this.grammar_error_on_node(AstNode.child_in_list(members, 0), DiagA_mapped_type_may_not_declare_properties_or_methods)"""
new = """        this.grammar_error_on_node(AstNode.child_in_list(members, AstNode.list_count(members) - 1), DiagA_mapped_type_may_not_declare_properties_or_methods)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkInferType's ANCESTOR WALK REDUCED TO ONE STEP — *is my own parent a
# conditional type whose extends type I am*. `string extends (infer W) ? W : never`
# then reports TS1338 on a legal declaration, because the infer's parent is the
# PARENTHESIZED type and the relation is one level further up. FindAncestor starting
# AT the node is what makes the difference, and the parenthesized line of the fixture
# is the only thing in the corpus that can show it.
old = """        var n node
        var found false
        while n <> null
        {"""
new = """        var n node
        var found false
        while n <> null
        {
            if n <> node
                break"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE IDENTITY HALF OF THE INFER PREDICATE DROPPED — any conditional-type ancestor
# will do, never mind which branch. `string extends number ? infer X : never` stops
# reporting; one diagnostic disappears, so the row is ungated on diagcheck and the
# count is its content. It is the reason the fixture carries a TRUE-branch infer as
# well as a bare one.
old = """            if Checker.kind_or_unknown(parent) = KindConditionalType
            {
                if AstNode.conditional_extends_type_of(parent) = n
                {
                    set found: true
                    break
                }
            }"""
new = """            if Checker.kind_or_unknown(parent) = KindConditionalType
            {
                set found: true
                break
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ checkTypePredicate REPORTS UNCONDITIONALLY. `(x: unknown) => x is string` — a
# function type, one of the seven kinds the reference's list admits — then reports
# TS1228 as well. The negative line of the fixture is the whole of what catches it.
old = """        let parent Checker.type_predicate_parent_of(node)
        if parent = null
        {"""
new = """        let parent Checker.type_predicate_parent_of(node)
        if true
        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE PREDICATE'S KIND LIST WIDENED WITH ConstructorType, which is what a reader
# who thought *any signature may carry a predicate* would write. TS1228 disappears
# from the fixture; ungated on diagcheck, and the count is the row. A construct
# signature's return type may NOT be a predicate and the reference's seven-kind list
# is the statement of that.
old = """        if pk = KindMethodSignature
            set eligible: true"""
new = """        if pk = KindMethodSignature
            set eligible: true
        if pk = KindConstructorType
            set eligible: true"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE JSDoc-DOT SCAN COMPARES THE TOKEN AGAINST `<` INSTEAD OF `.`. Every
# ordinary `Box<number>` in the corpus then reports TS8020, because the guard above
# it — the type name's end against the type-argument list's pos — is TRUE for every
# generic type reference there is: the list's pos sits one character past the `<`.
# The scan is the whole of the test and the arithmetic guard is only a pre-filter,
# which is exactly what this row says.
old = """                            if b.token_kind_at_position(name_end) = KindDotToken"""
new = """                            if b.token_kind_at_position(name_end) = KindLessThanToken"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ checkJSDocTypeIsInJsFile's JS-FILE GUARD REMOVED — AND IT MOVES NOTHING AT
# ALL, WHICH IS THE ROW'S ACTUAL CONTENT. The draft predicted a loud RED: the
# function is a no-op in a JavaScript file, which is where `*`, `?T` and `T!`
# legitimately live, so dropping the guard should turn every JSDoc type in the
# corpus's 150 JS units into a TS8020 the reference does not have. It does not,
# and the reason is a gate one step EARLIER: in a JS file a JSDoc type reaches the
# tree only through the reparser, hung off a declaration that carries
# NodeFlagsHasJSDoc — and check_source_element_worker reports
# `check-jsdoc-comments` and RETURNS for any such node before the switch is
# entered. So the guard is UNREACHABLE (§3.5v row 2), not merely uncovered, and no
# fixture can change that. g26 and g27 lift the gate as their PREMISE and turn the
# hole into a number.
old = """        if Parser.is_in_js_file(node)
            return
        let k AstNode.kind_of(node)"""
new = """        let k AstNode.kind_of(node)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE FIVE SIGNATURE KINDS UNWIRED — the case whose whole content was
# routing, and whose yield was the largest per line in the slice.
# checkSignatureDeclaration is untouched and still correct; only the switch and the
# arm table forget it, so a call signature, a construct signature, a function type,
# a constructor type and an index signature all report `check` at their own kind
# again. TS1098 and TS2300 go with it, and so does the index signature's report —
# three fixtures move at once, which is the point: five kinds were one line.
arm = '''        if k = KindConstructorType
        {
            this.check_signature_declaration(node)
            return
        }
        if k = KindFunctionType
        {
            this.check_signature_declaration(node)
            return
        }
        if k = KindCallSignature
        {
            this.check_signature_declaration(node)
            return
        }
        if k = KindConstructSignature
        {
            this.check_signature_declaration(node)
            return
        }
        if k = KindIndexSignature
        {
            this.check_signature_declaration(node)
            return
        }
'''
tab = '''        if k = KindConstructorType
            return true
        if k = KindFunctionType
            return true
        if k = KindCallSignature
            return true
        if k = KindConstructSignature
            return true
        if k = KindIndexSignature
            return true
'''
assert s.count(arm) == 1, s.count(arm)
assert s.count(tab) == 1, s.count(tab)
open(p, "w").write(s.replace(arm, "").replace(tab, ""))
PY

cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW: check_source_element_worker's JSDoc GATE LIFTED. Every node
# carrying NodeFlagsHasJSDoc is checked instead of reported, which is the condition
# g24 turned out to be standing behind. On its own it is a large measurement — the
# whole `check-jsdoc-comments` column becomes something else — and its job here is
# to be g27's partner: the DIFFERENCE between the two is what the JS-file guard
# actually protects.
old = """        if (AstNode.flags_of(node) & NodeFlagsHasJSDoc) <> 0
        {
            this.record_unported("check-jsdoc-comments", k)
            this.spend_ambient_report_of_container(node)
            return
        }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, ""))
PY

cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ g26 PLUS g24 — the gate lifted AND the JS-file guard removed. Read against
# g26 rather than against the baseline, the difference is the population
# checkJSDocTypeIsInJsFile's first line protects: every JSDoc type node in a
# JavaScript file that the reparser hung on a declaration. Slice 60's g14 technique
# one dimension along — a report that cannot be first is measured by lifting
# whatever stands in front of it and saying so at the row.
gate = """        if (AstNode.flags_of(node) & NodeFlagsHasJSDoc) <> 0
        {
            this.record_unported("check-jsdoc-comments", k)
            this.spend_ambient_report_of_container(node)
            return
        }
"""
assert s.count(gate) == 1, s.count(gate)
s = s.replace(gate, "")
old2 = """        if Parser.is_in_js_file(node)
            return
        let k AstNode.kind_of(node)"""
new2 = """        let k AstNode.kind_of(node)"""
assert s.count(old2) == 1, s.count(old2)
open(p, "w").write(s.replace(old2, new2))
PY

# ── the dry run ─────────────────────────────────────────────────────────────

bold "DRY RUN — every patch against a COPY of the tree"
DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24 g25 g26 g27; do
  cp "$CHECKER" "$DRY/copy"
  if python3 "$PATCHDIR/$id.py" "$DRY/copy" 2> "$DRY/err"; then
    printf '  %s  ok\n' "$id"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 checkArrayType's recursion removed"                            "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the three bare-ForEachChild arms made NO-OPS"                  "$CHECKER" "$PATCHDIR/g02.py"
control "g03 checkTypeOperator's recursion removed"                         "$CHECKER" "$PATCHDIR/g03.py"
control "g04 checkTupleType's element recursion removed"                    "$CHECKER" "$PATCHDIR/g04.py"
control "g05 checkTypeLiteral's members walk removed"                       "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the unique-operand kind test INVERTED"                       "$CHECKER" "$PATCHDIR/g06.py"
control "g07 WalkUpParenthesizedTypes' climb removed"                       "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the const flag read from the DECLARATION, not its list"        "$CHECKER" "$PATCHDIR/g08.py"
control "g09 TS1333's span moved to the NAME"                               "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the unique binding-name test dropped"                        "$CHECKER" "$PATCHDIR/g10.py"
control "g11 readonly's TupleType allowance removed"                        "$CHECKER" "$PATCHDIR/g11.py"
control "g12 readonly reported on the whole node, not its first token"      "$CHECKER" "$PATCHDIR/g12.py"
control "g13 checkTupleType SKIPS the variadic element instead of BREAKING" "$CHECKER" "$PATCHDIR/g13.py"
control "g14 getArrayElementTypeNode forced to answer null"                 "$CHECKER" "$PATCHDIR/g14.py"
control "g15 TS1257 reported on the TUPLE, not the element"                 "$CHECKER" "$PATCHDIR/g15.py"
control "g16 TS5086/TS5087 moved to the MEMBER"                             "$CHECKER" "$PATCHDIR/g16.py"
control "g17 checkGrammarMappedType's call removed"                         "$CHECKER" "$PATCHDIR/g17.py"
control "g18 TS7061 on the LAST member"                                     "$CHECKER" "$PATCHDIR/g18.py"
control "g19 checkInferType's ancestor walk reduced to ONE step"            "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the infer extends-type IDENTITY test dropped"                  "$CHECKER" "$PATCHDIR/g20.py"
control "g21 checkTypePredicate reports UNCONDITIONALLY"                    "$CHECKER" "$PATCHDIR/g21.py"
control "g22 the predicate's kind list widened with ConstructorType"        "$CHECKER" "$PATCHDIR/g22.py"
control 'g23 the JSDoc-dot scan compares the token against <'                       "$CHECKER" "$PATCHDIR/g23.py"
control "g24 checkJSDocTypeIsInJsFile's JS-file guard removed"              "$CHECKER" "$PATCHDIR/g24.py"
control "g25 the five signature kinds UNWIRED from the switch"              "$CHECKER" "$PATCHDIR/g25.py"
control "g26 the JSDoc GATE lifted (g27's premise)"                            "$CHECKER" "$PATCHDIR/g26.py"
cp "$WORK/last.tags" "$WORK/g26.tags"
control "g27 g26 + the JS-file guard removed"                                  "$CHECKER" "$PATCHDIR/g27.py" "$WORK/g26.tags"

echo
echo "################################################################"
bold "RESTORED — checker.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" | tail -3
