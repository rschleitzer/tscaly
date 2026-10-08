#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice56.sh — the slice-56 battery, and the first one in this file set
# that needs TWO instruments.
#
# ★★★ WHY TWO. checkBindingElement's two lines split cleanly in half by what can
# observe them. checkGrammarBindingElement produces four DIAGNOSTICS, which
# tests/diagcheck.sh gates in its one direction (a line we invent, move, or
# mis-code). checkVariableLikeDeclaration's binding-element block produces NO
# diagnostic at all — its whole observable effect is which TAG the unit's
# unported report carries, because the deferral RETURNS and the type dimension
# reports. diagcheck cannot see a tag, and no yardstick compares one: the
# `unported` column is a work list, not an answer the reference has. So the
# second instrument is a PIN, and it is built to be self-calibrating rather than
# hand-written — it captures the five fixtures' tags from the UNPATCHED build and
# every row is red if any of them moves.
#
# ★★★ WHAT THE PIN CAN AND CANNOT SAY, stated because an instrument whose scope
# is narrower than its claim is the trap it exists to prevent. It compares this
# port against ITSELF, so it can say that a control changed something and never
# that the unchanged answer is right. What makes each expectation defensible is
# written in the fixture that produces it: every tag in the table is one term of
# the reference's own control flow, named at its line.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: both instruments
# read the reference dumps run.sh produced, and a filtered run would rewrite part
# of that tree. Each row builds the package and the dumper into a scratch
# directory, points the instruments at it, leaves tests/out alone, restores the
# source and PROVES the restore with `cmp`.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice56.sh 2>&1 | tee /tmp/battery56.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The seven fixtures the PIN reads. Three of them hold ONE statement each, and
# that is a measurement decision rather than a style: a unit carries ONE unported
# tag, so a term whose only effect is to change which report comes FIRST cannot be
# witnessed by a line sitting behind another statement's report.
TAGFILES="
$FIX/checker_binding_element_renamed_in_type.ts
$FIX/checker_binding_element_renamed_into_pattern.ts
$FIX/checker_binding_element_renamed_in_variable.ts
$FIX/checker_binding_element_computed_property.ts
$FIX/checker_binding_element_rest_not_last.ts
$FIX/checker_binding_element_rest_trailing_comma.ts
$FIX/checker_binding_element_rest_initializer.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl56)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

# The PIN: one line per fixture, "<basename> <tag> <detail>".
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
  echo "  the PIN — the five fixtures' unported tags on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the pin would be comparing two empties."
    exit 2
  fi
  echo
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

control() {   # $1 = label, $2 = file, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  cp "$2" "$WORK/orig"
  if ! python3 "$3" "$2"; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    cp "$WORK/orig" "$2"
    return 1
  fi
  echo "  patched $2"
  if ! build_diag_bin; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    cp "$WORK/orig" "$2"
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
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  pin       unmoved — all seven fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
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

baseline

# ── g1: TS2462 compares against the LAST element ─────────────────────────────

cat > "$WORK/g1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `node.AsNode() != core.LastOrNil(elements.Nodes)`. Pointing the search at
# index 0 inverts the population exactly: every rest element that IS last (the
# legal shape, which the corpus is full of) reports TS2462, and the three illegal
# ones in checker_binding_element_rest_not_last.ts go quiet. It INVENTS lines, so
# diagcheck sees it.
old = """                set last: AstNode.child_in_list(elements, n - 1)
"""
new = """                set last: AstNode.child_in_list(elements, 0)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g1 TS2462 compares against the last element" "$CHECKER" "$WORK/g1.py"

# ── g2: TS2462's SPAN ────────────────────────────────────────────────────────

cat > "$WORK/g2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A SPAN-ONLY row. grammarErrorOnNode goes through GetErrorRangeForNode, which
# for a declaration answers the NAME's range — so the plausible mistake is not
# "the name instead of the node" (they are the same answer here) but the node's
# own POS, which is the FULL start and includes the `...` and the trivia before
# it. `var { ...a, b }` then reports at 5 instead of at 9.
old = """            if node <> last
                return this.grammar_error_on_node(node, DiagA_rest_element_must_be_last_in_a_destructuring_pattern)
"""
new = """            if node <> last
                return this.grammar_error_at_pos(AstNode.pos_of(node), 1, DiagA_rest_element_must_be_last_in_a_destructuring_pattern)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g2 TS2462's span" "$CHECKER" "$WORK/g2.py"

# ── g3: TS2462's CODE ────────────────────────────────────────────────────────

cat > "$WORK/g3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A CODE-ONLY row, same span and same order — the cheapest demonstration that
# the dump compares the code, and the reason the four reports of this function may
# be transcribed without their message arguments (§3.5ct).
old = """                return this.grammar_error_on_node(node, DiagA_rest_element_must_be_last_in_a_destructuring_pattern)
"""
new = """                return this.grammar_error_on_node(node, DiagA_rest_element_cannot_have_a_property_name)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g3 TS2462's code" "$CHECKER" "$WORK/g3.py"

# ── g4: the trailing-comma result is DISCARDED ───────────────────────────────

cat > "$WORK/g4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED WITH A FALLING COUNT, and the count is the row. Upstream
# discards this result and the two reports around it both `return`, so returning
# it turns the block into a chain and drops the property-name report on
# `var { ...a: b, } = o;` — the one line in the corpus that collects two
# diagnostics from ONE binding element. diagcheck cannot see a missing line
# (§3.5cz's f13), so the number is the whole gate: 133 -> 132.
old = """            this.check_grammar_for_disallowed_trailing_comma(elements, DiagA_rest_parameter_or_binding_pattern_may_not_have_a_trailing_comma)
"""
new = """            if this.check_grammar_for_disallowed_trailing_comma(elements, DiagA_rest_parameter_or_binding_pattern_may_not_have_a_trailing_comma)
                return true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g4 the trailing-comma result is discarded" "$CHECKER" "$WORK/g4.py"

# ── g5: TS2566's span is the NAME ────────────────────────────────────────────

cat > "$WORK/g5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The report is `grammarErrorOnNode(node.Name(), …)` and the tempting reading
# is the PROPERTY name — the thing the message is about. `{ ...a: b }` then
# reports on `a` instead of on `b`, two characters away, and it is the only span
# in this function where the two candidates are different nodes.
old = """            if AstNode.property_name_of(node) <> null
                return this.grammar_error_on_node(AstNode.name_of(node), DiagA_rest_element_cannot_have_a_property_name)
"""
new = """            if AstNode.property_name_of(node) <> null
                return this.grammar_error_on_node(AstNode.property_name_of(node), DiagA_rest_element_cannot_have_a_property_name)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g5 TS2566's span is the name" "$CHECKER" "$WORK/g5.py"

# ── g6: TS1186 reports at the `=`, not at the initializer ────────────────────

cat > "$WORK/g6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the `- 1` and the span is the initializer's FULL start — the character
# right after the `=`. One character, and it is the whole content of the
# reference's own comment at the line (*Error on equals token which immediately
# precedes the initializer*). checker_binding_element_rest_initializer.ts's second
# line, with three spaces on each side, is the one that says the offset is
# relative to the `=` and not to the literal.
old = """                return this.grammar_error_at_pos(AstNode.pos_of(initializer) - 1, 1, DiagA_rest_element_cannot_have_an_initializer)
"""
new = """                return this.grammar_error_at_pos(AstNode.pos_of(initializer), 1, DiagA_rest_element_cannot_have_an_initializer)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g6 TS1186 reports at the equals sign" "$CHECKER" "$WORK/g6.py"

# ── g7: TS1186's REPORTER ────────────────────────────────────────────────────

cat > "$WORK/g7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The third reporter exists because this span belongs to no node (§3.5cw).
# Routing the report through grammarErrorOnNode puts it on the element's name
# instead, which is what a port that had only two reporters would have to write —
# so the row measures the reporter and not the arithmetic.
old = """                return this.grammar_error_at_pos(AstNode.pos_of(initializer) - 1, 1, DiagA_rest_element_cannot_have_an_initializer)
"""
new = """                return this.grammar_error_on_node(node, DiagA_rest_element_cannot_have_an_initializer)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g7 TS1186's reporter" "$CHECKER" "$WORK/g7.py"

# ── g8: the two `if dot_dot_dot <> null` blocks, folded ──────────────────────

cat > "$WORK/g8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ EXPECTED UNGATED ON BOTH INSTRUMENTS WITH EVERY NUMBER UNMOVED, AND THE
# PREDICTION IS THE ROW. The first draft of the comment at this function claimed
# the two blocks must be kept apart; they need not be, because every path out of
# the first that skips the second is a `return`, so the initializer test is
# reached in exactly the same states either way. The row exists to hold that
# proof to a number — §3.5cz's merge lesson makes the opposite reflex cheap, and
# an argument without a measurement is how the wrong one survives.
old = """            if AstNode.property_name_of(node) <> null
                return this.grammar_error_on_node(AstNode.name_of(node), DiagA_rest_element_cannot_have_a_property_name)
        }
        if dot_dot_dot <> null
        {
            let initializer AstNode.initializer_of(node)
            if initializer <> null
                return this.grammar_error_at_pos(AstNode.pos_of(initializer) - 1, 1, DiagA_rest_element_cannot_have_an_initializer)
        }
"""
new = """            if AstNode.property_name_of(node) <> null
                return this.grammar_error_on_node(AstNode.name_of(node), DiagA_rest_element_cannot_have_a_property_name)
            let initializer AstNode.initializer_of(node)
            if initializer <> null
                return this.grammar_error_at_pos(AstNode.pos_of(initializer) - 1, 1, DiagA_rest_element_cannot_have_an_initializer)
        }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g8 the two rest blocks, folded" "$CHECKER" "$WORK/g8.py"

# ── t1: the deferral's RETURN ────────────────────────────────────────────────

cat > "$WORK/t1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW THE SECOND INSTRUMENT EXISTS FOR. The append is kept and only the
# `return` goes, so no diagnostic changes anywhere — the reference's TS2842 is
# behind the symbol either way — and diagcheck is blind to it. The PIN sees it:
# checker_binding_element_renamed_in_type.ts stops answering the function's own
# report and answers `get-type-for-binding-element-parent`, because the binding
# element now runs on into the type dimension.
old = """                renamed_binding_elements_in_types.add(node)
                return
"""
new = """                renamed_binding_elements_in_types.add(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t1 the deferral's return" "$CHECKER" "$WORK/t1.py"

# ── t2: the deferral's IsIdentifier term ─────────────────────────────────────

cat > "$WORK/t2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `{a: {b}}` renames into a PATTERN, which is not the shape the reference
# forbids. Dropping the term defers it too, and
# checker_binding_element_renamed_into_pattern.ts — one statement, on purpose —
# flips from the type dimension to the function's own report.
old = """                if AstNode.kind_of(name) = KindIdentifier
                {
                    if Binder.is_part_of_parameter_declaration(node)
"""
new = """                if true
                {
                    if Binder.is_part_of_parameter_declaration(node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t2 the deferral's identifier term" "$CHECKER" "$WORK/t2.py"

# ── t3: the deferral's IsPartOfParameterDeclaration term ─────────────────────

cat > "$WORK/t3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THIS ROW PREDICTED THE WRONG ANSWER AND IS KEPT WITH THE CORRECTION, which
# is worth more than the row. The prediction was that dropping the term would
# defer `var { c: d } = o;`, leave the file with nothing to report, and make
# checkUnusedRenamedBindingElements' own tag visible for the only time on either
# corpus. It does defer — but the ENCLOSING variable declaration then reaches its
# own hole (`get-widened-type-for-variable-like-declaration` at a
# VariableDeclaration), which is still earlier than the file's end. So the reader
# stays unreachable and t6 is the row that measures it. ★What this row actually
# gates is the term: TWO fixtures move, and both move to the CONTAINER's hole
# rather than to the element's — which is the shape of every deferral in this
# block. ★It also exercises the null direction of GetContainingFunction, which
# the term it removes is what makes unreachable.
old = """                    if Binder.is_part_of_parameter_declaration(node)
                    {
                        if Binder.node_is_missing(AstNode.body_of(Checker.get_containing_function(node)))
"""
new = """                    if true
                    {
                        if Binder.node_is_missing(AstNode.body_of(Checker.get_containing_function(node)))
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t3 the deferral's parameter term" "$CHECKER" "$WORK/t3.py"

# ── t4: the two reports of the block, in the reference's order ───────────────

cat > "$WORK/t4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ record_unported keeps the FIRST report, so the ORDER of the block's last two
# steps is observable and nothing else about them is. Swapping them makes
# checker_binding_element_computed_property.ts answer the type dimension instead
# of the computed property name — one of the thirteen stage-1 units this slice
# moves, moved again.
old = """            if prop_name <> null
            {
                if AstNode.kind_of(prop_name) = KindComputedPropertyName
                    this.record_unported("check-computed-property-name", KindBindingElement)
            }
            this.record_unported("get-type-for-binding-element-parent", KindBindingElement)
"""
new = """            this.record_unported("get-type-for-binding-element-parent", KindBindingElement)
            if prop_name <> null
            {
                if AstNode.kind_of(prop_name) = KindComputedPropertyName
                    this.record_unported("check-computed-property-name", KindBindingElement)
            }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t4 the block's two reports, in order" "$CHECKER" "$WORK/t4.py"

# ── t5: the !IsBindingElement guard on the type walk ─────────────────────────

cat > "$WORK/t5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED ON BOTH WITH EVERY NUMBER UNMOVED, AND THAT IS THE CLAIM
# WRITTEN AT THE LINE: a BindingElement carries no type annotation, so the
# accessor answers null and check_source_element returns at its own first line.
# The guard is transcribed because dropping it would make the port depend on that
# accessor's arm list instead of on the reference's own test — and a row that
# must not move is still a row, or the argument has no measurement.
old = """        if is_binding_element = false
            this.check_source_element(type_node)
"""
new = """        this.check_source_element(type_node)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t5 the type-walk guard" "$CHECKER" "$WORK/t5.py"

# ── t6: the reader's report ──────────────────────────────────────────────────

cat > "$WORK/t6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED ON BOTH WITH EVERY NUMBER UNMOVED, and the number is ZERO
# by the same argument §3.5cz's f14 makes: the reader runs last and the only route
# to its list is a parameter, whose function reports first. Removing the report
# therefore moves nothing — which is the claim. ★t3 was written to be the row that
# makes it visible for once and does NOT reach it either (see there): no shape
# this battery could build gets past the CONTAINER's own hole, so the report is
# emitted for §3.5cz's f14 reason alone — not emitting it would claim the drain is
# ported.
old = """        if renamed_binding_elements_in_types.get_length() = 0
            return
        this.record_unported("get-symbol-of-declaration", KindBindingElement)
"""
new = """        if renamed_binding_elements_in_types.get_length() = 0
            return
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "t6 the reader's report" "$CHECKER" "$WORK/t6.py"

# ── g9: the whole arm, clipped ───────────────────────────────────────────────

cat > "$WORK/g9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ THE COVERAGE CLAIM FROM THE OTHER SIDE, and it must print slice 55's
# baseline to the digit: with KindBindingElement off the ported list the arm is
# never entered, every binding element reports `check 209` again, and diagcheck
# returns to what §3.5cz measured. Both instruments see it — the diagnostics fall
# and all seven pinned tags move — which is what a whole slice being absent looks
# like.
old = """        if k = KindBindingElement
            return true
        false
    }
"""
new = """        false
    }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
control "g9 the whole binding-element arm, clipped" "$CHECKER" "$WORK/g9.py"

echo
echo "################################################################"
bold "DONE — 15 rows"
echo "Six rows break a live diagnostic and five break the block's control flow"
echo "on the PIN (four of them gated by the pin ALONE). g4 is ungated on"
echo "diagcheck and carries its falling count; g8,"
echo "t5 and t6 are ungated on BOTH and each PREDICTED that — g8 that the two"
echo "rest blocks are equivalent, t5 that a binding element has no type node, t6"
echo "that the reader's tag is unreachable. An ungated row that did not predict"
echo "its own silence is a hole in the battery, not a result — and t3 is the row"
echo "that predicted the WRONG answer and is kept with the correction written in."
