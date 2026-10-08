#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice24.sh — the slice-24 control battery, twenty-two of them.
#
# Slice 24 is checkJSSyntax: the pass that reports TypeScript-only syntax found in
# a JavaScript file. Each entry below breaks exactly ONE of its claims and measures
# what turns red. A row of the result table and a
# `run` here carry the same label, deliberately, so the two can be diffed.
#
# ★★★ THIS SLICE'S CONTROLS ARE UNUSUALLY SHARP, and the reason is the dump
# section rather than the port. Until the ast dump grew a J section, checkJSSyntax
# was INVISIBLE to both yardsticks in both directions — so a control aimed at it
# would have reported UNGATED whatever it broke. Every red below is a red the
# suite could not have produced yesterday, which is the argument for having built
# the section before the calls.
#
# ★ THE NUMBERS ARE A MEASUREMENT OF ONE TREE ON ONE DAY. Re-run after any change
# to this pass and expect them to MOVE. What must not change without an argument
# is a row's VERDICT: a RED row going UNGATED means the claim has lost its witness.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice24.sh 2>&1 | tee /tmp/battery24.log
#
# 1 baseline + 22 controls + 1 verifying run = 24 runs. See controls-slice22.sh's
# header for the arithmetic and for why the shared baseline is safe.
#
# ★★★ SEVENTEEN OF THE TWENTY-TWO ARE RED. The five that are not each get one of
# §3.5v's four answers rather than being left as a bare "nothing moved", and two
# of them are the interesting kind:
#
#   c2   UNREACHABLE. The guard's second half asks whether the NODE ITSELF is
#        reparsed, and no reparsed node is ever handed to check_js_syntax — the
#        reparser MUTATES a node the parser already built rather than routing a
#        synthesized one back through a parse routine. The tests that do the work
#        are the four INNER ones, which c2a–c2d aim at; two of those are red.
#   c2c  INDISTINGUISHABLE, and by an INTERACTION rather than by luck. A wholly
#        reparsed type-parameter list has no recorded RANGE either — the reparser
#        does not build it through parse_delimited_list — so c3's mechanism
#        suppresses it independently, and disabling this one alone moves nothing.
#        A list is never PARTLY reparsed: every reparser arm that writes one first
#        checks that there is none (`if fun.TypeParameters() == nil`).
#   c2d  UNREACHABLE. A parameter is checked while it is PARSED, before withJSDoc
#        runs on the function that encloses it, so the question token `@param {T}
#        [b]` synthesizes does not exist yet at the moment of the check. The other
#        two hosts of that arm — a property and a method — have no reparser arm
#        that writes a question token at all.
#   c5   UNREACHABLE. Only a PARAMETER's modifier list has its range read, and a
#        parameter's modifiers come from parse_modifiers; the two single-modifier
#        builders serve an arrow function and a constructor type. The recording is
#        there because the reference records it, not because anything reads it.
#   c13  INDISTINGUISHABLE by construction, and the code says so where the guard
#        is written: checkJSSyntax's own first test is the same question, so for
#        any file that is not JavaScript the list is empty and handing it over
#        prints nothing either way.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
P=packages/tscaly/0.1.1/tscaly/parser.scaly
A=packages/tscaly/0.1.1/tscaly/ast.scaly

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
BATTERY_START=$(python3 -c 'import time; print(time.time())')
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── the two halves of the guard ──────────────────────────────────────────────
#
# They need a control each rather than one between them: dropping the JS-ness test
# reports everything everywhere, dropping the Reparsed test reports everything the
# JSDoc reparser synthesized. One fixture cannot tell those apart.

run "c1 the pass never runs" <<SPEC
FILE $P
<<<OLD
        if (AstNode.flags_of(n) & NodeFlagsJavaScriptFile) = 0
            return n
>>>NEW
        if true
            return n
SPEC

run "c2 a node synthesized by the JSDoc reparser is checked too" <<SPEC
FILE $P
<<<OLD
        if (AstNode.flags_of(n) & (NodeFlagsJSDoc | NodeFlagsReparsed)) <> 0
            return n
>>>NEW
        if false
            return n
SPEC

# ★ c2 patches the guard, which asks whether the NODE ITSELF is reparsed. The
# three below patch the four INNER Reparsed tests, which ask it of a thing the
# node CONTAINS — and those are the ones the JSDoc reparser actually reaches,
# because it mutates a node the parser already built rather than routing a
# synthesized one back through a parse routine.

run "c2a a reparsed TYPE ANNOTATION is reported" <<SPEC
FILE $P
<<<OLD
                    if (AstNode.flags_of(t) & NodeFlagsReparsed) = 0
                        this.js_error_at_range(t.pos, t.end, DiagType_annotations_can_only_be_used_in_TypeScript_files)
>>>NEW
                    this.js_error_at_range(t.pos, t.end, DiagType_annotations_can_only_be_used_in_TypeScript_files)
SPEC

run "c2b a reparsed MODIFIER is reported" <<SPEC
FILE $P
<<<OLD
                        if (AstNode.flags_of(m) & NodeFlagsReparsed) = 0
                        {
                            let mk AstNode.kind_of(m)
>>>NEW
                        if true
                        {
                            let mk AstNode.kind_of(m)
SPEC

run "c2c a wholly reparsed type-parameter or type-argument LIST is reported" <<SPEC
FILE $P
<<<OLD
                if (AstNode.flags_of(e) & NodeFlagsReparsed) = 0
                    return true
>>>NEW
                return true
SPEC

run "c2d a reparsed QUESTION TOKEN is reported" <<SPEC
FILE $P
<<<OLD
                if (AstNode.flags_of(q) & NodeFlagsReparsed) = 0
                {
                    if AstNode.is_question_token(q)
>>>NEW
                if true
                {
                    if AstNode.is_question_token(q)
SPEC

# ── the LIST-RANGE side table, which is this slice's one new mechanism ────────

run "c3 a list's range is never recorded, so no list-ranged diagnostic is reported" <<SPEC
FILE $P
<<<OLD
        if list = null
            return
        list_ranges.add(ListRange(list, pos, end))
>>>NEW
        if list = null
            return
SPEC

run "c4 a list's range is DERIVED from its elements instead of recorded" <<SPEC
FILE $P
<<<OLD
        ; from the elements.
        this.record_list_range(list, pos, this.node_pos())
>>>NEW
        ; from the elements.
        if (list.get_length() as int) > 0
        {
            let derived_first *(list.get_buffer() + 0)
            let derived_last *(list.get_buffer() + ((list.get_length() as int) - 1))
            this.record_list_range(list, derived_first.pos, derived_last.end)
        }
SPEC

run "c5 a single-modifier list gets a computed span instead of the modifier's own" <<SPEC
FILE $P
<<<OLD
        ; \`p.newModifierList(modifier.Loc, ...)\` — this list's range IS the one
        ; modifier's, not a span computed from the token stream.
        this.record_list_range(list, m.pos, m.end)
>>>NEW
        this.record_list_range(list, pos, this.node_pos())
SPEC

# ── the two guards that are about a TYPE rather than about a file ─────────────

run "c6 a parameter of a TYPE is checked like a parameter of a function" <<SPEC
FILE $P
<<<OLD
        set parameter_check_js: (flags & ParseFlagsType) = 0
>>>NEW
        set parameter_check_js: true
SPEC

run "c7 an index signature's parameter is checked" <<SPEC
FILE $P
<<<OLD
        set parameter_check_js: false
        let parameters this.parse_bracketed_list(PCParameters, KindOpenBracketToken, KindCloseBracketToken)
>>>NEW
        let parameters this.parse_bracketed_list(PCParameters, KindOpenBracketToken, KindCloseBracketToken)
SPEC

run "c8 an accessor in a TYPE is checked like one in a class body" <<SPEC
FILE $P
<<<OLD
        if (flags & ParseFlagsType) = 0
            this.check_js_syntax(result)
        result
>>>NEW
        this.check_js_syntax(result)
        result
SPEC

# ── the LIST the diagnostics go to ───────────────────────────────────────────

run "c9 the JS diagnostics are merged into the ordinary diagnostic list" <<SPEC
FILE $P
<<<OLD
    procedure js_error_at_range(this, pos: int, end: int, code: int)
        js_diagnostics.add_direct(this.skip_range_trivia_pos(pos), end, code)
>>>NEW
    procedure js_error_at_range(this, pos: int, end: int, code: int)
        diagnostics.add_direct(this.skip_range_trivia_pos(pos), end, code)
SPEC

run "c10 the JS list is DEDUPED and marks the node, like a parse error" <<SPEC
FILE $P
<<<OLD
        js_diagnostics.add_direct(this.skip_range_trivia_pos(pos), end, code)
>>>NEW
        js_diagnostics.add(this.skip_range_trivia_pos(pos), end, code)
SPEC

run "c11 the diagnostic's pos keeps its leading trivia" <<SPEC
FILE $P
<<<OLD
        js_diagnostics.add_direct(this.skip_range_trivia_pos(pos), end, code)
>>>NEW
        js_diagnostics.add_direct(pos, end, code)
SPEC

run "c12 a speculation that was thrown away leaves its JS diagnostics behind" <<SPEC
FILE $P
<<<OLD
        js_diagnostics.truncate(saved.js_diagnostics_len)
>>>NEW
SPEC

run "c13 the list is handed to the SourceFile whatever the file is" <<SPEC
FILE $P
<<<OLD
        if (context_flags & NodeFlagsJavaScriptFile) = 0
            return null
        js_diagnostics
>>>NEW
        js_diagnostics
SPEC

# ── the widened accessors ────────────────────────────────────────────────────
#
# Each of these three had the arms its callers were believed to reach and had to
# be completed for this slice; a control per accessor says which of them the
# widening actually bought something for.

run "c14 modifiers_of has no arm for a class, a variable statement or a parameter" <<SPEC
FILE $A
<<<OLD
            when vstm: VariableStatement
                return vstm.modifiers
>>>NEW
            when vstm: VariableStatement
                return null
SPEC

run "c15 name_of has no arm for an interface or an enum" <<SPEC
FILE $A
<<<OLD
            when intf: InterfaceDeclaration
                return intf.name
>>>NEW
            when intf: InterfaceDeclaration
                return null
SPEC

run "c16 type_of has no arm for an as-expression" <<SPEC
FILE $A
<<<OLD
            when asex: AsExpression
                return asex.type_node
>>>NEW
            when asex: AsExpression
                return null
SPEC

# ── two arms whose ORDER is the diagnostic ───────────────────────────────────

run "c17 a body-less signature reports its return type instead" <<SPEC
FILE $P
<<<OLD
                    this.js_error_at_range(n.pos, n.end, DiagSignature_declarations_can_only_be_used_in_TypeScript_files)
                    set reported: true
>>>NEW
                    this.js_error_at_range(n.pos, n.end, DiagSignature_declarations_can_only_be_used_in_TypeScript_files)
SPEC

run "c18 a decorator's PLACEMENT is never checked" <<SPEC
FILE $P
<<<OLD
        this.check_js_decorator_syntax(n)
>>>NEW
        if false
            this.check_js_decorator_syntax(n)
SPEC

# ── and the run that makes the eighteen numbers above mean anything ──────────

echo
echo "################################################################"
echo "the 24th run: reproducing the baseline from the restored tree ..."
FINAL=$(mktemp -t tscaly-final)
"$RUN" > "$FINAL" 2>&1 </dev/null
FINAL_RC=$?
if [ $FINAL_RC -ne 0 ]; then
  printf '\033[31m%s\033[0m\n' "the final run is not green (rc $FINAL_RC) — the battery left the tree broken."
  tail -30 "$FINAL"
  rm -f "$FINAL"
  exit 2
fi
if diff -q "$TSCALY_BASELINE" "$FINAL" > /dev/null 2>&1; then
  printf '\033[32m%s\033[0m\n' "BATTERY VERIFIED: the final report is byte-identical to the baseline."
else
  printf '\033[31m%s\033[0m\n' "THE FINAL REPORT DIFFERS FROM THE BASELINE — every number above is suspect."
  diff "$TSCALY_BASELINE" "$FINAL" | head -40
  rm -f "$FINAL"
  exit 1
fi
rm -f "$FINAL"

python3 -c 'import sys,time; d=time.time()-float(sys.argv[1]); print("battery wall time: %d min %d s (%d runs of the yardsticks)" % (d//60, d%60, 24))' "$BATTERY_START"
