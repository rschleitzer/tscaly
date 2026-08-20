#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice33.sh — the slice-33 control battery, twenty-eight of them.
#
# Slice 33 is the FLOW chapter's first slice: the two heads of the unported
# histogram, the BINARY EXPRESSION and the CALL, plus the three arms that are
# the same optional-chain branch (property access, element access, non-null).
#
# ★★★ READ THE UNGATED ROWS FIRST — there are eight of them and they are the
# slice's finding rather than a gap in it. The flow half is not ported, so most
# of what these functions DO is invisible here by construction; what is left is
# the traversal, and only three places in it are not ForEachChild's order. Of
# those three, exactly ONE can be exercised today:
#
#   the destructuring swap   LIVE — c13..c18 are red, on bind DIAGNOSTICS
#   the IIFE reorder         UNREACHABLE — the callee of an IIFE is a function
#                            expression or an arrow, and both of those `bind`
#                            arms are unported, so the unit reports either way
#                            and the two orders produce the same dump (c23, c24)
#   the binary MODIFIERS     UNREACHABLE — only the JSDoc reparser fills that
#                            slot, on an assignment declaration, which this
#                            slice reports (c20, and c22 for the Type slot)
#
# ★★★ AND ONE ROW IS ABOUT THE ORACLE RATHER THAN THE PORT, which is why the
# order fixtures are written the way they are: tests/oracle/symbols.go numbers
# symbols IN WALK ORDER, so the sequence the binder CREATES them in is not
# visible in the s section at all. The first draft of
# binder_destructuring_assignment.ts was four destructuring assignments with an
# object literal on each side, and it gated NOTHING — swapping the operands left
# the dump byte-identical. What is order-sensitive is the B section, which is a
# bind-order append, so every order fixture carries `eval = <n>` on each side
# and the strict-mode diagnostics are the witness. §3.5ap: a fixture that gates
# nothing is invisible until a control aims at it.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice33.sh 2>&1 | tee /tmp/battery33.log
#
# 1 baseline + 28 controls + 1 verifying run = 30 runs, about 32 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.0/tscaly/binder.scaly
P=packages/tscaly/0.1.0/tscaly/parser.scaly

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── the five arms exist at all ───────────────────────────────────────────────
#
# Each REPORTS rather than silently binding through the default arm: slice 32's
# c1 is why (ctl.sh's header has the account). Reporting is the pre-slice
# behaviour exactly, so the row measures what the arm UNLOCKS and nothing else.

run "c1 a BinaryExpression has a bind-children arm" <<SPEC
FILE $B
<<<OLD
            this.bind_binary_expression_flow(n)
            return
>>>NEW
            this.record_unported("bind-children", k)
            return
SPEC

run "c2 a CallExpression has a bind-children arm" <<SPEC
FILE $B
<<<OLD
        if k = KindCallExpression
        {
            this.bind_call_expression_flow(n)
            return
        }
>>>NEW
        if k = KindCallExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c3 a PropertyAccessExpression has one" <<SPEC
FILE $B
<<<OLD
        if k = KindPropertyAccessExpression
        {
            this.bind_access_expression_flow(n)
            return
        }
>>>NEW
        if k = KindPropertyAccessExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c4 an ElementAccessExpression has one" <<SPEC
FILE $B
<<<OLD
        if k = KindElementAccessExpression
        {
            this.bind_access_expression_flow(n)
            return
        }
>>>NEW
        if k = KindElementAccessExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c5 a NonNullExpression has one" <<SPEC
FILE $B
<<<OLD
        if k = KindNonNullExpression
        {
            this.bind_non_null_expression_flow(n)
            return
        }
>>>NEW
        if k = KindNonNullExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

# ── the classifier ───────────────────────────────────────────────────────────
#
# c6 is the row that says why the classifier is in this slice at all: with it
# answering None the port binds the JS assignment declarations as ordinary
# expressions and CLAIMS agreement, which the reference contradicts by declaring
# a symbol the port never made.

# ★ THE FIRST DRAFT OF c6 WAS REFUSED, and the refusal is the harness earning its
# keep: the three lines it anchored on are IDENTICAL in the binary arm and the
# call arm, so `record_unported` would have been disabled in one of them at
# random. The anchor now carries the comment line that only the binary arm has.
run "c6 the JS assignment declarations are REPORTED at all" <<SPEC
FILE $B
<<<OLD
            if adk <> JSDeclarationKindNone
                this.record_unported("assignment-declaration", adk)

            ; checkStrictModeBinaryExpression runs AFTER the switch and outside
>>>NEW
            if false
                this.record_unported("assignment-declaration", adk)

            ; checkStrictModeBinaryExpression runs AFTER the switch and outside
SPEC

run "c7 the Property kind is NOT JavaScript-gated" <<SPEC
FILE $P
<<<OLD
            if left.kind = KindPropertyAccessExpression
            {
                if is_entity_name_expression_ex(inner, is_in_js_file(left))
                {
                    let nm AstNode.property_access_name_of(left)
>>>NEW
            if left.kind = KindPropertyAccessExpression
            {
                if is_entity_name_expression_ex(inner, is_in_js_file(left)) and is_in_js_file(left)
                {
                    let nm AstNode.property_access_name_of(left)
SPEC

run "c8 a require() call in a JS file is REPORTED" <<SPEC
FILE $B
<<<OLD
                if Parser.is_require_call(n, false)
                    this.record_unported("commonjs-require", 0)
>>>NEW
                if false
                    this.record_unported("commonjs-require", 0)
SPEC

# ★★★ c9 IS NOT THE ROW ITS FIRST LABEL CLAIMED, and it is kept because the
# correction is the lesson (ctl.sh's header: an anchor that is unique is not
# thereby the anchor you meant). Patching the PREDICATE breaks every caller, and
# its loudest caller is not the classifier at all — it is
# Binder.expression_is_alias, which decides Alias vs Property for `export = x`.
# Every one of the fourteen red units is an export-assignment or
# export-default one. c9b is the row that was meant: the classifier's own use of
# it, patched at the site.
run "c9 the entity-name predicate is load-bearing — for expression_is_alias" <<SPEC
FILE $P
<<<OLD
    function is_entity_name_expression_ex(n: pointer[AstNode], allow_js: bool) returns bool
    {
        if n = null
            return false
>>>NEW
    function is_entity_name_expression_ex(n: pointer[AstNode], allow_js: bool) returns bool
    {
        if n <> null
            return true
        if n = null
            return false
SPEC

run "c9b the classifier's own ENTITY-NAME test" <<SPEC
FILE $P
<<<OLD
            if left.kind = KindPropertyAccessExpression
            {
                if is_entity_name_expression_ex(inner, is_in_js_file(left))
                {
                    let nm AstNode.property_access_name_of(left)
>>>NEW
            if left.kind = KindPropertyAccessExpression
            {
                if true
                {
                    let nm AstNode.property_access_name_of(left)
SPEC

# ── the strict-mode diagnostic ───────────────────────────────────────────────

run "c10 the binary arm's strict-mode check runs" <<SPEC
FILE $B
<<<OLD
            this.check_strict_mode_binary_expression(n)
        }
>>>NEW
            this.record_unported("strict-mode-binary", 0)
        }
SPEC

run "c11 its ASSIGNMENT-OPERATOR test" <<SPEC
FILE $B
<<<OLD
        if Parser.is_assignment_operator(AstNode.binary_operator_kind(n)) = false
            return
>>>NEW
        if false
            return
SPEC

run "c12 its LEFT-HAND-SIDE test" <<SPEC
FILE $B
<<<OLD
        if Parser.is_left_hand_side_expression_kind(AstNode.kind_of(left)) = false
            return
        if Parser.is_assignment_operator(AstNode.binary_operator_kind(n)) = false
>>>NEW
        if false
            return
        if Parser.is_assignment_operator(AstNode.binary_operator_kind(n)) = false
SPEC

# ── the destructuring swap, which is the slice's one LIVE order ──────────────

run "c13 a destructuring assignment has an arm of its own" <<SPEC
FILE $B
<<<OLD
            if Binder.is_destructuring_assignment(n)
            {
>>>NEW
            if false
            {
SPEC

run "c14 the two branches of the swap are not interchangeable" <<SPEC
FILE $B
<<<OLD
        if in_assignment_pattern
        {
            set in_assignment_pattern: false
            this.bind(AstNode.binary_operator_token_of(n))
>>>NEW
        if in_assignment_pattern = false
        {
            set in_assignment_pattern: false
            this.bind(AstNode.binary_operator_token_of(n))
SPEC

run "c15 the arm CARRIES the enclosing pattern's flag over" <<SPEC
FILE $B
<<<OLD
                set in_assignment_pattern: save_in_assignment_pattern
                this.bind_destructuring_assignment_flow(n)
>>>NEW
                set in_assignment_pattern: false
                this.bind_destructuring_assignment_flow(n)
SPEC

run "c16 the assignment-pattern label restores the flag before descending" <<SPEC
FILE $B
<<<OLD
            set in_assignment_pattern: save_in_assignment_pattern
            this.bind_each_child(n)
            return
>>>NEW
            this.bind_each_child(n)
            return
SPEC

run "c17 bind_children CLEARS the flag on entry" <<SPEC
FILE $B
<<<OLD
        let save_in_assignment_pattern in_assignment_pattern
        set in_assignment_pattern: false
>>>NEW
        let save_in_assignment_pattern in_assignment_pattern
SPEC

run "c18 is_destructuring_assignment's LITERAL test" <<SPEC
FILE $B
<<<OLD
        let lk AstNode.kind_of(left)
        if lk = KindObjectLiteralExpression
            return true
        lk = KindArrayLiteralExpression
>>>NEW
        let lk AstNode.kind_of(left)
        true
SPEC

# ── the binary traversal ─────────────────────────────────────────────────────

run "c19 the plain branch binds LEFT before RIGHT" <<SPEC
FILE $B
<<<OLD
        this.bind(AstNode.binary_left_of(n))
        this.bind(AstNode.binary_type_of(n))

        ; A comma expression's two halves each go through
>>>NEW
        this.bind(AstNode.binary_right_of(n))
        this.bind(AstNode.binary_type_of(n))

        ; A comma expression's two halves each go through
SPEC

run "c20 the MODIFIERS are not bound" <<SPEC
FILE $B
<<<OLD
        this.bind(AstNode.binary_left_of(n))
        this.bind(AstNode.binary_type_of(n))

        ; A comma expression's two halves each go through
>>>NEW
        this.bind_each(AstNode.modifiers_of(n))
        this.bind(AstNode.binary_left_of(n))
        this.bind(AstNode.binary_type_of(n))

        ; A comma expression's two halves each go through
SPEC

run "c21 the LOGICAL branch is not the plain one" <<SPEC
FILE $B
<<<OLD
        if logical
        {
            this.bind_logical_like_expression(n)
            return
        }
>>>NEW
        if false
        {
            this.bind_logical_like_expression(n)
            return
        }
SPEC

run "c22 the plain branch binds the TYPE slot" <<SPEC
FILE $B
<<<OLD
        this.bind(AstNode.binary_left_of(n))
        this.bind(AstNode.binary_type_of(n))

        ; A comma expression's two halves each go through
>>>NEW
        this.bind(AstNode.binary_left_of(n))

        ; A comma expression's two halves each go through
SPEC

# ── the call ─────────────────────────────────────────────────────────────────

run "c23 the IIFE reorder" <<SPEC
FILE $B
<<<OLD
            this.bind_each(AstNode.type_arguments_of(n))
            this.bind_each(AstNode.call_arguments_of(n))
            this.bind(AstNode.expression_of(n))
            return
>>>NEW
            this.bind_each_child(n)
            return
SPEC

run "c24 SkipParentheses in the IIFE test" <<SPEC
FILE $B
<<<OLD
        let callee Parser.skip_parentheses(AstNode.expression_of(n))
>>>NEW
        let callee AstNode.expression_of(n)
SPEC

# ── the optional chain ───────────────────────────────────────────────────────

run "c25 the chain branch of the call arm" <<SPEC
FILE $B
<<<OLD
        if Binder.is_optional_chain(n)
        {
            this.bind_optional_chain_flow(n)
            return
        }

        let callee Parser.skip_parentheses(AstNode.expression_of(n))
>>>NEW
        if Binder.is_optional_chain(n)
        {
            this.bind_each_child(n)
            return
        }

        let callee Parser.skip_parentheses(AstNode.expression_of(n))
SPEC

run "c26 the chain REST binds a call's arguments" <<SPEC
FILE $B
<<<OLD
            this.bind(AstNode.question_dot_token_of(n))
            this.bind_each(AstNode.type_arguments_of(n))
            this.bind_each(AstNode.call_arguments_of(n))
>>>NEW
            this.bind(AstNode.question_dot_token_of(n))
            this.bind_each(AstNode.type_arguments_of(n))
SPEC

run "c27 is_optional_chain's KIND test" <<SPEC
FILE $B
<<<OLD
        let k AstNode.kind_of(n)
        if k = KindPropertyAccessExpression
            return true
        if k = KindElementAccessExpression
            return true
        if k = KindCallExpression
            return true
        k = KindNonNullExpression
>>>NEW
        true
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl33-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl33-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl33-final.log | head -30
  exit 1
fi
