#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice54.sh — the slice-54 battery. Every row goes through
# tests/diagcheck.sh, for slices 49-53's reason: no yardstick counter can move,
# because checkVariableLikeDeclaration stops at getSymbolOfDeclaration, so not one
# variable declaration can be claimed. Checker matched is 10 / 109 before and after
# everything below.
#
# ★★★ THIS SLICE'S SUBJECT IS THE OPPOSITE OF SLICE 53's: nine of
# checkGrammarVariableDeclaration's reports are REACHABLE and the corpus reaches
# eight of them, so twelve rows break a live claim and the ungated four are
# ungated for four DIFFERENT reasons — one of which is the most useful row here.
#
# ★★★ TWELVE ROWS ARE RED AND FOUR ARE UNGATED. f13 IS THE ROW TO READ FIRST. It fills the one hole this slice leaves —
# isInitializerSimpleLiteralEnumReference — with the GUESS `not an enum
# reference`, and comes back UNGATED, because on this corpus the guess is right
# every time: no ambient const is initialized from a real enum member, so
# `checkExpressionCached(expr).flags & EnumLike` is 0 wherever it is asked. The
# instrument therefore cannot tell a lucky guess from a port, which is exactly why
# the term is a REPORT and not a `return false` — and the day the corpus grows one
# enum member the guess becomes an invented TS1254 that nobody would look for.
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report. Every gated row therefore breaks its
# claim in the direction that INVENTS a line, moves a span or changes a code.
# f14/f15/f16 are the three that could only remove work, and each is printed with
# the NUMBER that makes it a measurement rather than a shrug (§3.5cw's lesson: a
# row that says *ungated* and nothing else gets read as *nothing to see*).
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory, points
# diagcheck's BIN at it, leaves tests/out alone, restores the source and PROVES the
# restore with `cmp`.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice54.sh 2>&1 | tee /tmp/battery54.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl54)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

diag_baseline() {
  echo "################################################################"
  bold "DIAGNOSTICS BASELINE"
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
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

diag_control() {   # $1 = label, $2 = file, $3 = python patch file
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
  local consistent differing speaking
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  local diags
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  cp "$WORK/orig" "$2"
  if ! cmp -s "$WORK/orig" "$2"; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  echo "  RESTORE VERIFIED   $2 byte-identical"
  echo
  if [ "$rc" != 0 ]; then
    green "RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    red "UNGATED: every line we print is still a subsequence of the reference's."
    echo "  Speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
    echo "  Decide which of §3.5v's four kinds this is — and note that a control"
    echo "  which REMOVES a diagnostic, or narrows the port's COVERAGE, is ungated"
    echo "  here by construction (header)."
  fi
  return 0
}

diag_baseline

# ── f1: TS1492 needs the using/await-using BLOCK SCOPE ───────────────────────

cat > "$WORK/f1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The binding-pattern refusal is a using-only rule; aim its await-using arm at
# every block scope and each destructuring declaration in the corpus reports
# TS1492. checker_variable_uninitialized.ts is the smallest case of it, and
# checker_variable_binding_pattern_await_using.ts is what the arm is FOR.
old = """            if block_scope_kind = NodeFlagsAwaitUsing
                return this.grammar_error_on_node(node, DiagX_0_declarations_may_not_have_binding_patterns)
"""
new = """            if true
                return this.grammar_error_on_node(node, DiagX_0_declarations_may_not_have_binding_patterns)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f1 TS1492 needs the using block scope" "$CHECKER" "$WORK/f1.py"

# ── f2: TS1155's keyword arms do not include `let` ───────────────────────────

cat > "$WORK/f2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ `let` is the ONE block-scope keyword that may be left uninitialized, and the
# three-arm switch is where that is said. Adding a fourth arm reports TS1155 on
# every bare `let` in the corpus — which is also the row that proves the arm list
# is read rather than a constant.
old = """                    if block_scope_kind = NodeFlagsConst
                        return this.grammar_error_on_node(node, DiagX_0_declarations_must_be_initialized)
"""
new = """                    if block_scope_kind = NodeFlagsConst
                        return this.grammar_error_on_node(node, DiagX_0_declarations_must_be_initialized)
                    if block_scope_kind = NodeFlagsLet
                        return this.grammar_error_on_node(node, DiagX_0_declarations_must_be_initialized)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f2 TS1155's keyword arms exclude let" "$CHECKER" "$WORK/f2.py"

# ── f3: the destructuring report is TS1182 and not TS1155 ────────────────────

cat > "$WORK/f3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ A CODE-ONLY row: same span, same order, one wrong number. It is the cheapest
# demonstration that the dump compares the code (§3.5ck) and the reason the
# four-way keyword switch above may collapse to one message without a keyword
# string.
old = """                            return this.grammar_error_on_node(node, DiagA_destructuring_declaration_must_have_an_initializer)
"""
new = """                            return this.grammar_error_on_node(node, DiagX_0_declarations_must_be_initialized)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f3 the destructuring report's CODE" "$CHECKER" "$WORK/f3.py"

# ── f4: the definite-assignment span is the TOKEN ────────────────────────────

cat > "$WORK/f4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ A SPAN-ONLY row. Report on the declaration instead of the `!` and the code and
# the order are untouched — the only difference is that error_range_for_node then
# answers the declaration's NAME. It is the one report of this function that does
# not point at the declaration, so this is where a span regression would hide.
old = """                if initializer <> null
                    return this.grammar_error_on_node(exclamation_token, DiagDeclarations_with_initializers_cannot_also_have_definite_assignment_assertions)
"""
new = """                if initializer <> null
                    return this.grammar_error_on_node(node, DiagDeclarations_with_initializers_cannot_also_have_definite_assignment_assertions)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f4 the definite-assignment SPAN is the ! token" "$CHECKER" "$WORK/f4.py"

# ── f5: the definite-assignment fork picks by INITIALIZER first ──────────────

cat > "$WORK/f5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The three-way choice is an ORDER: an initializer decides before a missing type
# annotation does. Swapping the two tests leaves both codes in the file and both
# spans right, and answers TS1264 where the reference answers TS1263.
old = """                if initializer <> null
                    return this.grammar_error_on_node(exclamation_token, DiagDeclarations_with_initializers_cannot_also_have_definite_assignment_assertions)
                if type_node = null
                    return this.grammar_error_on_node(exclamation_token, DiagDeclarations_with_definite_assignment_assertions_must_also_have_type_annotations)
"""
new = """                if type_node = null
                    return this.grammar_error_on_node(exclamation_token, DiagDeclarations_with_definite_assignment_assertions_must_also_have_type_annotations)
                if initializer <> null
                    return this.grammar_error_on_node(exclamation_token, DiagDeclarations_with_initializers_cannot_also_have_definite_assignment_assertions)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f5 the definite-assignment fork's ORDER" "$CHECKER" "$WORK/f5.py"

# ── f6: a `!` in a typed, uninitialised variable STATEMENT is legal ──────────

cat > "$WORK/f6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The four-term disjunction is what LETS a definite-assignment assertion exist.
# Force it and `var a!: number` — the negative line of
# checker_variable_definite_assignment.ts — reports TS1255, the catch-all.
old = """            if not_permitted
            {
"""
new = """            if true
            {
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f6 a legal ! is the disjunction's negative" "$CHECKER" "$WORK/f6.py"

# ── f7: the __esModule walk reads the element's NAME ─────────────────────────

cat > "$WORK/f7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ ONE claim, two effects, and both follow from it: the walk asks a binding
# element's NAME. Ask its PROPERTY NAME instead and `export var { __esModule: q }`
# — the documented negative half of checker_variable_esmodule_marker.ts — reports
# TS1216 at a position the reference has none, while the array pattern's element,
# which has no property name, stops reporting. The invented line is what reddens.
old = """            let en AstNode.name_of(element)
            if en <> null
                return this.check_grammar_for_es_module_marker_in_binding_name(en)
"""
new = """            let en AstNode.property_name_of(element)
            if en <> null
                return this.check_grammar_for_es_module_marker_in_binding_name(en)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f7 the __esModule walk reads the element's NAME" "$CHECKER" "$WORK/f7.py"

# ── f8: the let-name walk reads the element's NAME ───────────────────────────

cat > "$WORK/f8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ f7's claim one function along, where the reference's own two walks differ in
# everything BUT this: `let` is a legal property name and an illegal binding name,
# so asking the property name reports TS2480 on `const { let: z }`.
old = """            let en AstNode.name_of(element)
            if en <> null
                this.check_grammar_name_in_let_or_const_declarations(en)
"""
new = """            let en AstNode.property_name_of(element)
            if en <> null
                this.check_grammar_name_in_let_or_const_declarations(en)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f8 the let-name walk reads the element's NAME" "$CHECKER" "$WORK/f8.py"

# ── f9: the ambient initializer's const-like test ────────────────────────────

cat > "$WORK/f9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ isVarConstLike is what separates TS1254 from TS1039. Force it false and every
# ambient `const x = 1` in the corpus — a declaration file's commonest line —
# reports *initializers are not allowed* instead of nothing. It is the loudest row
# here and the one that says the const/let distinction is read.
old = """        if AstNode.kind_of(node) = KindVariableDeclaration
        {
            if this.is_var_const_like(node)
                set is_const_or_readonly: true
        }
"""
new = """        if AstNode.kind_of(node) = KindVariableDeclaration
        {
            if false
                set is_const_or_readonly: true
        }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f9 the ambient initializer's const-like test" "$CHECKER" "$WORK/f9.py"

# ── f10: the TYPE-ANNOTATION half of the same condition ──────────────────────

cat > "$WORK/f10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE DIRECTION OF THIS ROW WAS WRONG ON THE FIRST DRAFT, AND WHY IS WORTH THE
# LINE. It read `if false` — drop the type-node test — expecting TS1254 where the
# reference answers TS1039; it came back UNGATED at 60/111, because the fixture's
# typed declaration is `const d: number = 1` and `1` IS a valid literal, so removing
# the test removes the report instead of changing its code. For a test whose two
# branches are two different reports, only ONE direction invents a line, and WHICH
# one depends on the fixture's payload — so the row forces the test TRUE instead, and
# every ambient initializer in the corpus then reports TS1039, the valid literals
# included.
old = """        if type_node <> null
            return this.grammar_error_on_node(initializer, DiagInitializers_are_not_allowed_in_ambient_contexts)
"""
new = """        if true
            return this.grammar_error_on_node(initializer, DiagInitializers_are_not_allowed_in_ambient_contexts)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f10 the type-annotation half of the ambient condition" "$CHECKER" "$WORK/f10.py"

# ── f11: `true` is a legal ambient const initializer ─────────────────────────

cat > "$WORK/f11.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ One arm of the five-way disjunction, removed: an ambient `const e = true` then
# reports TS1254. Together with f12 this is what makes the three negative lines of
# checker_variable_ambient_initializer.d.ts non-decorative.
old = """        if ik = KindTrueKeyword
            return false
"""
new = """        if false
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f11 true is a legal ambient const initializer" "$CHECKER" "$WORK/f11.py"

# ── f12: a prefix MINUS over a numeric literal is legal ──────────────────────

cat > "$WORK/f12.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ The half of isInitializerStringOrNumberLiteralExpression that is NOT a kind
# test. Remove it and `const f = -1` reports TS1254 — and note the predicate is
# minus-only on purpose: ast.is_signed_numeric_literal would also admit `+1`, which
# the reference refuses.
old = """        if Checker.is_initializer_signed_numeric_literal(initializer)
            return false
"""
new = """        if false
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f12 a prefix minus over a numeric literal is legal" "$CHECKER" "$WORK/f12.py"

# ── f13: the enum-reference hole, filled with a GUESS ────────────────────────

cat > "$WORK/f13.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW THIS BATTERY EXISTS FOR. Replace the two unported reports with the
# guess `not an enum reference`, so TS1254 fires on every ambient const initialized
# from a property or element access. EXPECTED UNGATED — and that is the finding, not
# a shrug: the corpus holds no ambient const initialized from a real enum member, so
# `checkExpressionCached(expr).flags & EnumLike` is 0 wherever the reference asks
# it, and the guess agrees on every unit. The instrument cannot tell a lucky guess
# from a port here, which is precisely why the term is a REPORT — and
# checker_variable_ambient_initializer_enum_ref.d.ts is the deferred witness that
# says what turns it live.
old = """        if ik = KindPropertyAccessExpression
        {
            this.record_unported("is-initializer-simple-literal-enum-reference", ik)
            return false
        }
        if ik = KindElementAccessExpression
        {
            this.record_unported("is-initializer-simple-literal-enum-reference", ik)
            return false
        }
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f13 the enum-reference hole filled with a guess" "$CHECKER" "$WORK/f13.py"

# ── f14: the no-arm family, one kind removed ─────────────────────────────────

cat > "$WORK/f14.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED, AND NOT ONE COUNTER MOVES — WHICH IS STRONGER THAN THE FALLING NUMBER
# THE FIRST DRAFT PREDICTED. Take `any` out of the no-arm family and the 35 stage-1
# units annotated `any` report `check AnyKeyword`, a tag naming a function the
# reference does not have — but `record_unported` does not stop the WALK, only the
# dump, so every diagnostic those units emit is emitted either way and diagcheck
# reads 60/112 both times. The tag is the ONLY observable, which is exactly why
# kind_has_no_check_arm is an argument about the reference's switch (§3.5cy) and not
# a measurement: no instrument in this package can fail on it.
old = """        if k = KindAnyKeyword
            return true
        if k = KindUnknownKeyword
"""
new = """        if false
            return true
        if k = KindUnknownKeyword
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f14 the no-arm family, any removed" "$CHECKER" "$WORK/f14.py"

# ── f15: the arm itself ──────────────────────────────────────────────────────

cat > "$WORK/f15.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ EXPECTED UNGATED WITH A NUMBER — §3.5cx's f7 in this slice's shape. Clip the
# whole arm and the counters must fall back to slice 53's coverage ON THIS CORPUS,
# which is the only way to state a coverage claim from the other side. Read the
# `speaking/diags` figures against the baseline; the delta is what this slice buys.
old = """    procedure check_variable_declaration(this, node: pointer[AstNode])
    {
        this.check_grammar_variable_declaration(node)
        this.check_variable_like_declaration(node)
    }
"""
new = """    procedure check_variable_declaration(this, node: pointer[AstNode])
    {
        this.record_unported("check", KindVariableDeclaration)
    }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f15 the whole arm, clipped" "$CHECKER" "$WORK/f15.py"

# ── f16: the type-annotation WALK ────────────────────────────────────────────

cat > "$WORK/f16.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ EXPECTED UNGATED, and the reason is worth the row: not ONE of the twenty-six
# type kinds whose arm the reference has is ported, so the walk this slice adds
# cannot produce a diagnostic yet — its whole yield is the histogram moving one
# level down. The row exists so that the slice which ports a type arm finds a
# measurement here instead of assuming the walk was already gated.
old = """        this.check_source_element(type_node)
        if AstNode.is_binding_pattern(name)
"""
new = """        if AstNode.is_binding_pattern(name)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f16 the type-annotation walk" "$CHECKER" "$WORK/f16.py"

echo
echo "################################################################"
bold "DONE — 16 rows"
echo "Twelve rows break a live report; f13/f14/f15/f16 are UNGATED and each carries"
echo "its own argument above — read them against §3.5v's four kinds. f15 is the"
echo "coverage claim from the other side: it must print slice 53's 49/93."
