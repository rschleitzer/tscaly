#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice52.sh — the slice-52 battery. Every row goes through
# tests/diagcheck.sh, for the reason slices 49, 50 and 51 give: no yardstick
# counter can move, because checkFunctionOrMethodDeclaration always ends in a
# report (checkFunctionOrConstructorSymbol), so not one function unit can be
# claimed. Checker matched is 10 / 109 before and after everything below.
#
# ★★★ ITS SUBJECT IS THE LONGEST GRAMMAR CHAIN THIS PORT HAS RUN END TO END —
# checkGrammarFunctionLikeDeclaration's five terms, against slice 51's two: the
# modifiers, the type-parameter list, the parameter list, the arrow guard and the
# use-strict directive. So the rows can aim at the CHAIN as well as at its parts:
# f9 points one term at the wrong list, f15 unwires the arm that reaches the chain
# at all.
#
# ★★★ THE INSTRUMENT IS ONE-DIRECTIONAL, WHICH DECIDES HOW EVERY ROW IS WRITTEN.
# diagcheck compares our C section as a SUBSEQUENCE of the reference's, so it
# cannot see a diagnostic we FAIL to report. Fourteen of the seventeen rows below
# therefore break their claim in the direction that INVENTS a line, moves a span or
# changes a code. The three that cannot (f15, f16, f17) are COVERAGE or TAG claims
# and are read off the numbers they name instead (§3.5v's fourth kind).
#
# ★★ THREE MECHANISMS OF THIS SLICE HAVE NO GATE AT ALL, and saying so is cheaper
# than a row that proves nothing. `get_function_flags` is read at exactly two
# places, both of them record_unported calls, so a wrong answer moves a TAG and no
# diagnostic (f17 is its stand-in); check_grammar_arrow_function's body past the
# guard is unreachable from this arm by construction (f16); and the correction of
# `strict_null_checks` from false to TRUE that rode along with this slice is
# provably unobservable — its one reader creates two extra intrinsic types, and the
# dump prints type NAMES, so all 5 350 dumps of the five yardsticks are
# byte-identical across the flip. That measurement is the checksum it carries
# instead of a row.
#
# ★★★ AND THE BATTERY MEASURED ITS OWN REACH, WHICH IS THE THING TO READ FIRST.
# Every gated row carries the count it actually reddens, because four of them redden
# exactly ONE unit — their own fixture — and the first draft of each claimed "every
# … in the corpus". The split is sharp: f2 (15), f6 (8), f8 (93) and f9 (85) reach
# the corpus; f1, f3, f5, f7, f10, f11, f12 and f14 reach only the fixture, and f4
# and f13 only their fixture's two and three lines. ★The most useful of those
# measurements is a fact about the CORPUS rather than about the port: a `"use
# strict"` prologue inside a function body occurs, in the whole of stage 1, only
# where this slice put one — so the three use-strict fixtures are not redundant with
# the corpus, they ARE the corpus for that check.
#
# ★★ THE ROWS DO NOT GO THROUGH ctl.sh, for slice 48's reason: diagcheck reads the
# reference dumps run.sh produced, and a filtered run would rewrite part of that
# tree. Each row builds the package and the dumper into a scratch directory, points
# diagcheck's BIN at it, leaves tests/out alone, restores the source and PROVES the
# restore with `cmp`.
#
# ★ f11 patches binder.scaly rather than checker.scaly — FindUseStrictPrologue and
# its text comparison live in the reference's binder.go, and this port keeps them
# there because the source TEXT is the binder's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # the artifact tree, first
#   packages/tscaly/tests/controls-slice52.sh 2>&1 | tee /tmp/battery52.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
BINDER=$PKG/0.1.0/tscaly/binder.scaly

. packages/tscaly/tests/toolchain.sh || exit 2

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Every row compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl52)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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

# ── f1: the rest-not-last report is at the `...` TOKEN ───────────────────────

cat > "$WORK/f1.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ grammarErrorOnNode(parameter.DotDotDotToken, …). The parameter's own error
# range is its NAME, so reporting on the parameter is the same code at a different
# place — three characters wide instead of at the ellipsis, which is exactly the
# failure a subsequence test is sharpest on.
old = """                    return this.grammar_error_on_node(dot_dot_dot, DiagA_rest_parameter_must_be_last_in_a_parameter_list)
"""
new = """                    return this.grammar_error_on_node(parameter, DiagA_rest_parameter_must_be_last_in_a_parameter_list)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f1 the rest-not-last report is at the '...' token" "$CHECKER" "$WORK/f1.py"

# ── f2: `not last` is an INDEX test, and it is what makes the check a check ──

cat > "$WORK/f2.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the index test and EVERY rest parameter reports TS1014, legal ones
# included. MEASURED: 15 units, speaking 47 → 57 — so this is one of the four rows
# that reddens the corpus rather than only the fixture, and the count is the number
# of stage-1 units holding a legal rest parameter in a FUNCTION declaration, not the
# number holding one at all (a method's or an arrow's is not walked yet).
old = """                if index <> parameter_count - 1
                    return this.grammar_error_on_node(dot_dot_dot, DiagA_rest_parameter_must_be_last_in_a_parameter_list)
"""
new = """                return this.grammar_error_on_node(dot_dot_dot, DiagA_rest_parameter_must_be_last_in_a_parameter_list)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f2 a rest parameter is illegal only when it is not LAST" "$CHECKER" "$WORK/f2.py"

# ── f3: the trailing-comma guard is the PARAMETER'S ambient flag ─────────────

cat > "$WORK/f3.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ `parameter.Flags & ast.NodeFlagsAmbient == 0`. The flag is propagated down
# from the `declare`, so this guard is what makes `declare function f(...a: any[],)`
# legal, and it is what separates a per-PARAMETER test from a per-FILE one — which
# is why the fixture carries both spellings in one .ts. MEASURED: 1 unit, +1
# diagnostic. The corpus holds no other ambient rest parameter with a trailing
# comma, so this row lives on its fixture and says so.
old = """                if (AstNode.flags_of(parameter) & NodeFlagsAmbient) = 0
                    this.check_grammar_for_disallowed_trailing_comma(parameters, DiagA_rest_parameter_or_binding_pattern_may_not_have_a_trailing_comma)
"""
new = """                this.check_grammar_for_disallowed_trailing_comma(parameters, DiagA_rest_parameter_or_binding_pattern_may_not_have_a_trailing_comma)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f3 an ambient rest parameter may carry a trailing comma" "$CHECKER" "$WORK/f3.py"

# ── f4: the optional-rest report is at the `?` TOKEN ─────────────────────────

cat > "$WORK/f4.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ Three reports of this one arm have three different spans — the `...`, the `?`
# and the NAME — so a port that picked one node for all of them cannot be right
# about more than one. This row moves the second onto the first's.
old = """                if question <> null
                    return this.grammar_error_on_node(question, DiagA_rest_parameter_cannot_be_optional)
"""
new = """                if question <> null
                    return this.grammar_error_on_node(dot_dot_dot, DiagA_rest_parameter_cannot_be_optional)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f4 the optional-rest report is at the '?' token" "$CHECKER" "$WORK/f4.py"

# ── f5: the rest-initializer report is at the NAME ───────────────────────────

cat > "$WORK/f5.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★ The third of the three spans. Upstream reports this one on `parameter.Name()`
# and its neighbour one line up on the `?` token, which is the asymmetry
# checker_function_rest_parameter_initializer.ts exists to hold in one unit.
old = """                if initializer <> null
                    return this.grammar_error_on_node(AstNode.name_of(parameter), DiagA_rest_parameter_cannot_have_an_initializer)
"""
new = """                if initializer <> null
                    return this.grammar_error_on_node(dot_dot_dot, DiagA_rest_parameter_cannot_have_an_initializer)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f5 the rest-initializer report is at the parameter's NAME" "$CHECKER" "$WORK/f5.py"

# ── f6: question-mark-and-initializer needs BOTH ─────────────────────────────

cat > "$WORK/f6.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ Drop the initializer term and every OPTIONAL parameter reports TS1015.
# MEASURED: 8 units, speaking 47 → 53 — the corpus half of this check, next to the
# fixture's pair.
old = """                        if initializer <> null
                            return this.grammar_error_on_node(AstNode.name_of(parameter), DiagParameter_cannot_have_question_mark_and_initializer)
"""
new = """                        return this.grammar_error_on_node(AstNode.name_of(parameter), DiagParameter_cannot_have_question_mark_and_initializer)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f6 a question mark alone is not an error" "$CHECKER" "$WORK/f6.py"

# ── f7: a parameter with a DEFAULT is not a required one ─────────────────────

cat > "$WORK/f7.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE HALF OF required-after-optional THAT IS NOT ABOUT THE `?`. The condition
# is `seenOptionalParameter && parameter.Initializer == nil`, so `f(a?, b = 1)` is
# legal. MEASURED: 1 unit, +1 diagnostic — an optional parameter followed by a
# defaulted one is rare enough in stage 1 that the fixture is the whole witness,
# which is exactly why the fixture has that third function.
old = """                    if seen_optional_parameter
                    {
                        if initializer = null
                            return this.grammar_error_on_node(AstNode.name_of(parameter), DiagA_required_parameter_cannot_follow_an_optional_parameter)
                    }
"""
new = """                    if seen_optional_parameter
                        return this.grammar_error_on_node(AstNode.name_of(parameter), DiagA_required_parameter_cannot_follow_an_optional_parameter)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f7 a defaulted parameter after an optional one is legal" "$CHECKER" "$WORK/f7.py"

# ── f8: the OPTIONAL flag is state, set only by an optional parameter ────────

cat > "$WORK/f8.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW FOR THE LOOP'S ONLY PIECE OF STATE, AND THE LOUDEST IN THE BATTERY.
# Set it for every parameter and the second parameter of nearly every two-parameter
# function reports TS1016. MEASURED: 93 units, speaking 47 → 136 — the sharpest
# evidence that this check runs on the whole corpus and not only where a `?`
# appears.
old = """            else
            {
                if question <> null
                {
                    set seen_optional_parameter: true
"""
new = """            else
            {
                set seen_optional_parameter: true
                if question <> null
                {
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f8 only an OPTIONAL parameter sets the seen-optional state" "$CHECKER" "$WORK/f8.py"

# ── f9: the chain's second term is the TYPE parameter list ───────────────────

cat > "$WORK/f9.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW FOR THE `||` ITSELF. checkGrammarTypeParameterList fires on a list
# that EXISTS and is EMPTY, and a function's parameter list is exactly that whenever
# it takes no arguments — so pointing the term at the wrong list invents TS1098 on
# every `function f() {}`. MEASURED: 85 units, speaking 47 → 130, the second loudest
# row here, and the one that proves the chain is entered at all.
old = """        if this.check_grammar_type_parameter_list(AstNode.type_parameters_of(node))
            return true
        if this.check_grammar_parameter_list(AstNode.parameters_of(node))
"""
new = """        if this.check_grammar_type_parameter_list(AstNode.parameters_of(node))
            return true
        if this.check_grammar_parameter_list(AstNode.parameters_of(node))
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f9 the empty-list term of the chain is the TYPE parameter list" "$CHECKER" "$WORK/f9.py"

# ── f10: the use-strict directive must be in the PROLOGUE ────────────────────

cat > "$WORK/f10.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ FindUseStrictPrologue's `else return nil` IS the prologue rule: the run of
# directives ends at the first statement that is not one. Turn the walk into a
# SEARCH and `function g(a = 1) { let x = 1; "use strict"; }` reports — a shape the
# corpus holds far beyond the fixture, since a `"use strict"` in the middle of a
# body is ordinary dead code.
old = """            if AstNode.kind_of(statement) <> KindExpressionStatement
                return null
            let e AstNode.expression_of(statement)
            if e = null
                return null
            if AstNode.kind_of(e) <> KindStringLiteral
                return null
"""
new = """            if AstNode.kind_of(statement) = KindExpressionStatement
            {
                let e AstNode.expression_of(statement)
                if e <> null
                {
                    if AstNode.kind_of(e) = KindStringLiteral
                        if this.is_use_strict_prologue_directive(statement)
                            return statement
                }
            }
            if false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f10 a 'use strict' behind real code is not a directive" "$BINDER" "$WORK/f10.py"

# ── f11: the raw text is TWELVE bytes with MATCHING quotes ──────────────────

cat > "$WORK/f11.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ THE ROW FOR "RAW, NOT COOKED". Drop the length test and the closing-quote
# test and `"use strict but longer"` becomes a directive, because its first eleven
# bytes are the ones the loop below compares. Those two tests are the whole
# difference between reading the SOURCE TEXT and reading a prefix of it, which is
# what checker_function_use_strict_raw_text.ts's third function is there to catch.
old = """        if AstNode.end_of(e) - start <> 12
            return false
        let quote this.byte_at(start)
        if quote <> 0x22
        {
            if quote <> 0x27
                return false
        }
        if this.byte_at(start + 11) <> quote
            return false
"""
new = """        let quote this.byte_at(start)
        if quote <> 0x22
        {
            if quote <> 0x27
                return false
        }
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f11 the directive is twelve bytes between matching quotes" "$BINDER" "$WORK/f11.py"

# ── f12: the non-simple filter has exactly three terms ──────────────────────

cat > "$WORK/f12.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ A parameter is non-simple when it has an initializer, a binding-pattern NAME
# or a `...`. A TYPE ANNOTATION is not one of the three — it is the most plausible
# fourth term there is, and adding it makes every annotated parameter of a function
# with a `"use strict"` report TS1346. MEASURED: 1 unit, +2 diagnostics; see f14 for
# why the use-strict rows all live on their fixtures.
old = """            if AstNode.dot_dot_dot_token_of(parameter) <> null
                set is_non_simple: true
"""
new = """            if AstNode.dot_dot_dot_token_of(parameter) <> null
                set is_non_simple: true
            if AstNode.type_of(parameter) <> null
                set is_non_simple: true
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f12 a type annotation does not make a parameter non-simple" "$CHECKER" "$WORK/f12.py"

# ── f13: the two use-strict reports are at two different nodes ──────────────

cat > "$WORK/f13.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ One TS1346 per non-simple PARAMETER and one TS1347 on the DIRECTIVE. Swapping
# the two nodes keeps both codes and both counts and moves every span, which is the
# one failure mode a subsequence test catches without a single missing line.
old = """                this.error_on_node(parameter, DiagThis_parameter_is_not_allowed_with_use_strict_directive)
"""
new = """                this.error_on_node(use_strict_directive, DiagThis_parameter_is_not_allowed_with_use_strict_directive)
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f13 the parameter report is at the parameter, not at the directive" "$CHECKER" "$WORK/f13.py"

# ── f14: the directive is only reported when a parameter is non-simple ──────

cat > "$WORK/f14.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★ `if len(nonSimpleParameters) != 0` guards BOTH halves of the report upstream.
# Drop it and every function that opens with `"use strict"` reports TS1347 on the
# directive, whatever its parameters are; the fixture's fourth function is the
# smallest case. ★★★MEASURED: 1 unit, +1 diagnostic — so a `"use strict"` PROLOGUE
# inside a function body occurs, in the whole of stage 1, only where this slice put
# one. That is worth knowing rather than guessing: the three use-strict fixtures are
# not redundant with the corpus, they ARE the corpus for this check, and f10, f11,
# f12 and f14 all reddening exactly one unit is the same fact seen four times.
old = """        if non_simple = 0
            return false
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f14 a simple parameter list with 'use strict' says nothing" "$CHECKER" "$WORK/f14.py"

# ── f15: the arm is wired into the switch ────────────────────────────────────

cat > "$WORK/f15.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION, and it is the row for the SLICE ITSELF: unwire the
# kind and every function declaration reports `check` before the chain runs, so this
# port says NOTHING about any of them — which a subsequence test accepts. The gate is
# the counters. ★★★MEASURED: 47/90 falls back to **36/66**, which is slice 51's
# baseline to the digit — the coverage claim confirmed rather than asserted, and the
# cheapest form the confirmation could take.
old = """        ; Slice 52. The function declaration — the last of the switch's arms to be
        ; a HEAD, and the first whose grammar `||` this port runs to its end.
        if k = KindFunctionDeclaration
            return true
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f15 the FunctionDeclaration arm is wired into the switch" "$CHECKER" "$WORK/f15.py"

# ── f16: the arrow guard is what lets a function declaration continue ───────

cat > "$WORK/f16.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION AND WORTH A ROW ANYWAY. Invert the guard and the
# fourth term of the chain reports `check-grammar-arrow-function` for every function
# declaration instead of answering false — no diagnostic moves, because a report is
# not a diagnostic, and the whole visible effect is one row of tests/triage.py's
# histogram. It is the only instrument in this package that can see an UNPORTED tag,
# and this row is how that is remembered. MEASURED: 47/90 unchanged, both counters
# to the digit.
old = """        if AstNode.kind_of(node) <> KindArrowFunction
            return false
"""
new = """        if AstNode.kind_of(node) = KindArrowFunction
            return false
"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f16 checkGrammarArrowFunction returns for a function declaration" "$CHECKER" "$WORK/f16.py"

# ── f17: the parameter RECURSION is the histogram's next level ──────────────

cat > "$WORK/f17.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# ★★★ UNGATED BY CONSTRUCTION, and it is the row for what this slice BOUGHT rather
# than for what it checks. `c.checkSourceElements(node.Parameters())` is the step
# that moves 43 stage-1 units off `check FunctionDeclaration` and onto `check
# Parameter`; removing it changes no diagnostic at all — the parameters have no
# ported arm — and the whole difference is which kind the work list names. Read it
# off tests/triage.py: `check 170` disappears and `check 263` comes back. MEASURED:
# 47/90 unchanged, which is the claim: 43 units change their TAG and not one changes
# what we say about it.
old = """        this.check_source_elements(AstNode.parameters_of(node))
"""
new = """"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY
diag_control "f17 the parameter list is walked as source elements" "$CHECKER" "$WORK/f17.py"

echo
echo "################################################################"
bold "BATTERY 52 COMPLETE"
echo "Seventeen rows. Fourteen must be RED. Three are UNGATED and each says why:"
echo "f15 and f17 are COVERAGE rows read off diagcheck's two counters and"
echo "tests/triage.py's histogram, and f16's only observable is an UNPORTED TAG,"
echo "which no counter here carries. See the header for the three mechanisms of"
echo "this slice that have no row at all, and why a row would prove nothing."
