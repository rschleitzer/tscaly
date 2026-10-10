#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice35.sh — the slice-35 control battery, thirty-six of them.
#
# Slice 35 is the LAST fifteen arms of the reference's `bind` switch, plus the
# six bindChildren arms without which five of those fifteen would be invisible.
#
# ★★★ THAT PAIRING IS THE SLICE'S ARGUMENT AND THESE ROWS ARE WHERE IT IS
# CHECKED. A unit whose bindChildren arm is unported reports and returns, so its
# whole dump is the marker — the TS1102 on `delete x`, the TS1100 on `eval++`,
# the TS1344 on a labeled declaration and the catch clause's own check (reachable
# only under a `try`) would every one of them have shipped unmeasured. c15..c28
# are the rows that can only be red because c29..c34's arms exist.
#
# ★★ ROWS c3..c8 BREAK NOTHING IN A BODY, because those six arms have no body:
# the `this` keyword, `super`, a qualified name, a meta property, the `this` type
# and (bar one call) the binding element are pure FLOW upstream, and this port
# does not build flow. Each row puts the kind back on
# kind_has_unported_bind_arm — the pre-slice behaviour exactly — so what it
# measures is what the arm UNLOCKS, which for these six is the whole walk below
# them. Slice 34's c1..c4 are the same shape and its narrative has the arithmetic.
#
# ★ THE ORDER ROW (c35) rests on a fixture written to hit a SECTION rather than
# to contain a construct, slice 33's finding used as a tool for the second time:
# symbols are numbered in WALK order, so a bind ORDER is visible only in the B
# section. binder_binding_element_order.ts therefore pairs a future-reserved-word
# binding NAME (TS1212) with an `eval`/`arguments` INITIALIZER (TS1100) — the
# reference binds the initializer first, so the 1100 precedes the 1212, and
# routing the arm through bind_each_child swaps them.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice35.sh 2>&1 | tee /tmp/battery35.log
#
# 1 baseline + 36 controls + 1 verifying run = 38 runs, about 9 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.2/tscaly/binder.scaly
A=packages/tscaly/0.1.2/tscaly/ast.scaly

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

# ── the JSX attributes family ────────────────────────────────────────────────

run "c1 a JsxAttributes has a bind arm" <<SPEC
FILE $B
<<<OLD
        if k = KindJsxAttributes
            this.bind_jsx_attributes(n)
>>>NEW
        if k = KindJsxAttributes
        {
            this.record_unported("bind", k)
            return
        }
SPEC

run "c2 a JsxAttribute has one" <<SPEC
FILE $B
<<<OLD
        if k = KindJsxAttribute
            this.bind_jsx_attribute(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
        if k = KindJsxAttribute
        {
            this.record_unported("bind", k)
            return
        }
SPEC

# ── the six flow-only arms: what they unlock ─────────────────────────────────

run "c3 the this keyword's arm is ported" <<SPEC
FILE $B
<<<OLD
    function kind_has_unported_bind_arm(k: int) returns bool
        false
>>>NEW
    function kind_has_unported_bind_arm(k: int) returns bool
    {
        if k = KindThisKeyword
            return true
        false
    }
SPEC

run "c4 the super keyword's is" <<SPEC
FILE $B
<<<OLD
    function kind_has_unported_bind_arm(k: int) returns bool
        false
>>>NEW
    function kind_has_unported_bind_arm(k: int) returns bool
    {
        if k = KindSuperKeyword
            return true
        false
    }
SPEC

run "c5 the qualified name's is" <<SPEC
FILE $B
<<<OLD
    function kind_has_unported_bind_arm(k: int) returns bool
        false
>>>NEW
    function kind_has_unported_bind_arm(k: int) returns bool
    {
        if k = KindQualifiedName
            return true
        false
    }
SPEC

run "c6 the meta property's is" <<SPEC
FILE $B
<<<OLD
    function kind_has_unported_bind_arm(k: int) returns bool
        false
>>>NEW
    function kind_has_unported_bind_arm(k: int) returns bool
    {
        if k = KindMetaProperty
            return true
        false
    }
SPEC

run "c7 the this TYPE's is" <<SPEC
FILE $B
<<<OLD
    function kind_has_unported_bind_arm(k: int) returns bool
        false
>>>NEW
    function kind_has_unported_bind_arm(k: int) returns bool
    {
        if k = KindThisType
            return true
        false
    }
SPEC

run "c8 the binding element's is" <<SPEC
FILE $B
<<<OLD
    function kind_has_unported_bind_arm(k: int) returns bool
        false
>>>NEW
    function kind_has_unported_bind_arm(k: int) returns bool
    {
        if k = KindBindingElement
            return true
        false
    }
SPEC

# ── what the JSX arms say ────────────────────────────────────────────────────

run "c9 the attributes object's name is the internal jsxAttributes" <<SPEC
FILE $B
<<<OLD
        let nl Binder.internal_name(host, "jsxAttributes", &nd)
>>>NEW
        let nl Binder.internal_name(host, "object", &nd)
SPEC

run "c10 its FLAG is ObjectLiteral" <<SPEC
FILE $B
<<<OLD
        let nl Binder.internal_name(host, "jsxAttributes", &nd)
        this.bind_anonymous_declaration(n, SymbolFlagsObjectLiteral, nd, nl)
>>>NEW
        let nl Binder.internal_name(host, "jsxAttributes", &nd)
        this.bind_anonymous_declaration(n, SymbolFlagsTypeLiteral, nd, nl)
SPEC

run "c11 an attribute declares with the Property flag" <<SPEC
FILE $B
<<<OLD
            this.bind_jsx_attribute(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
            this.bind_jsx_attribute(n, SymbolFlagsMethod, SymbolFlagsPropertyExcludes)
SPEC

run "c12 an attribute's EXCLUDES are PropertyExcludes" <<SPEC
FILE $B
<<<OLD
            this.bind_jsx_attribute(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
            this.bind_jsx_attribute(n, SymbolFlagsProperty, SymbolFlagsNone)
SPEC

run "c13 a namespaced attribute name carries the COLON" <<SPEC
FILE $B
<<<OLD
                set *(buf + nsl): ":" as char
>>>NEW
                set *(buf + nsl): "-" as char
SPEC

run "c14 the NAMESPACE comes first in it" <<SPEC
FILE $B
<<<OLD
                let ns AstNode.namespaced_namespace_of(name)
                let nm AstNode.namespaced_name_of(name)
>>>NEW
                let nm AstNode.namespaced_namespace_of(name)
                let ns AstNode.namespaced_name_of(name)
SPEC

# ── the strict-mode grammar checks ───────────────────────────────────────────

run "c15 a with statement is reported" <<SPEC
FILE $B
<<<OLD
    procedure check_strict_mode_with_statement(this, n: pointer[AstNode])
        this.error_on_first_token(n, DiagX_with_statements_are_not_allowed_in_strict_mode)
>>>NEW
    procedure check_strict_mode_with_statement(this, n: pointer[AstNode])
    {
        if n <> null
            return
    }
SPEC

run "c16 a delete of an identifier is reported" <<SPEC
FILE $B
<<<OLD
        this.error_on_node(e, DiagX_delete_cannot_be_called_on_an_identifier_in_strict_mode)
>>>NEW
        ; the control removed this arm's only diagnostic
SPEC

run "c17 only an IDENTIFIER operand is reported" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(e) <> KindIdentifier
            return
        this.error_on_node(e, DiagX_delete_cannot_be_called_on_an_identifier_in_strict_mode)
>>>NEW
        this.error_on_node(e, DiagX_delete_cannot_be_called_on_an_identifier_in_strict_mode)
SPEC

run "c18 a postfix ++ on eval is reported" <<SPEC
FILE $B
<<<OLD
    procedure check_strict_mode_postfix_unary_expression(this, n: pointer[AstNode])
        this.check_strict_mode_eval_or_arguments(n, AstNode.postfix_unary_operand_of(n))
>>>NEW
    procedure check_strict_mode_postfix_unary_expression(this, n: pointer[AstNode])
    {
        if n <> null
            return
    }
SPEC

run "c19 a prefix ++ on eval is reported" <<SPEC
FILE $B
<<<OLD
        if op = KindPlusPlusToken
        {
            this.check_strict_mode_eval_or_arguments(n, AstNode.prefix_unary_operand_of(n))
            return
        }
>>>NEW
        if op = KindPlusPlusToken
            return
SPEC

run "c20 the prefix arm asks for ++ / -- " <<SPEC
FILE $B
<<<OLD
        let op AstNode.prefix_unary_operator_kind(n)
        if op = KindPlusPlusToken
>>>NEW
        let op AstNode.prefix_unary_operator_kind(n)
        this.check_strict_mode_eval_or_arguments(n, AstNode.prefix_unary_operand_of(n))
        if op = KindPlusPlusToken
SPEC

run "c21 a catch clause named eval is reported" <<SPEC
FILE $B
<<<OLD
        this.check_strict_mode_eval_or_arguments(n, AstNode.name_of(vd))
>>>NEW
        ; the control removed this arm's only diagnostic
SPEC

run "c22 the catch's name comes from the VARIABLE DECLARATION" <<SPEC
FILE $B
<<<OLD
        this.check_strict_mode_eval_or_arguments(n, AstNode.name_of(vd))
>>>NEW
        this.check_strict_mode_eval_or_arguments(n, AstNode.name_of(n))
SPEC

run "c23 a label in front of a declaration is reported" <<SPEC
FILE $B
<<<OLD
        if bad
            this.error_on_first_token(AstNode.label_name_of(n), DiagA_label_is_not_allowed_here)
>>>NEW
        if bad
            return
SPEC

run "c24 that report's span is the LABEL's first token" <<SPEC
FILE $B
<<<OLD
            this.error_on_first_token(AstNode.label_name_of(n), DiagA_label_is_not_allowed_here)
>>>NEW
            this.error_on_first_token(n, DiagA_label_is_not_allowed_here)
SPEC

run "c25 it asks is_declaration_statement" <<SPEC
FILE $B
<<<OLD
        var bad Binder.is_declaration_statement(st)
>>>NEW
        var bad true
SPEC

run "c26 and a VariableStatement besides" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(st) = KindVariableStatement
            set bad: true
>>>NEW
        ; the control removed the second half of the condition
SPEC

run "c27 a #constructor private name is reported" <<SPEC
FILE $B
<<<OLD
        this.error_on_node(n, DiagX_constructor_is_a_reserved_word)
>>>NEW
        ; the control removed this arm's only diagnostic
SPEC

run "c28 the text it compares carries the HASH" <<SPEC
FILE $B
<<<OLD
        if AstNode.identifier_text_is(n, "#constructor") = false
>>>NEW
        if AstNode.identifier_text_is(n, "constructor") = false
SPEC

# ★★★ The row for the defect this slice found. identifier_text_is had an
# Identifier arm and no PrivateIdentifier one, though the two SHARE
# IdentifierData — §3.5bb — so every private name compared as the empty string
# and checkPrivateIdentifier could never fire. It was found by the fixture
# written to gate c27, on the run meant to confirm it.
run "c29 a PrivateIdentifier's TEXT is readable at all" <<SPEC
FILE $A
<<<OLD
            when pid: PrivateIdentifier
            {
                set at: pid.text
                set alen: pid.text_len
            }
>>>NEW
SPEC

# ── the six bindChildren arms ────────────────────────────────────────────────
#
# Five of them ARE bindEachChild once the flow is removed, so a control routing
# one back into bind_each_child is UNGATED by construction (§3.5v's fourth row).
# What each row measures instead is the unlock: the arm reports, exactly as it
# did before this slice, and every unit containing that kind falls to unported —
# which is also the number that says how much of c15..c28 depends on it.

run "c30 the delete expression's bind_children arm is ported" <<SPEC
FILE $B
<<<OLD
        if k = KindDeleteExpression
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = KindDeleteExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c31 the postfix expression's is" <<SPEC
FILE $B
<<<OLD
        if k = KindPostfixUnaryExpression
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = KindPostfixUnaryExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c32 the prefix expression's is" <<SPEC
FILE $B
<<<OLD
        if k = KindPrefixUnaryExpression
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = KindPrefixUnaryExpression
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c33 the labeled statement's is" <<SPEC
FILE $B
<<<OLD
        if k = KindLabeledStatement
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = KindLabeledStatement
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c34 the try statement's is" <<SPEC
FILE $B
<<<OLD
        if k = KindTryStatement
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if k = KindTryStatement
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

# ★★★ The one observable ORDER claim in the group: the reference binds a binding
# element's INITIALIZER before its NAME, where child order has the name third.
run "c35 the binding element binds its INITIALIZER before its NAME" <<SPEC
FILE $B
<<<OLD
            this.bind(AstNode.dot_dot_dot_token_of(n))
            this.bind(AstNode.property_name_of(n))
            this.bind(AstNode.initializer_of(n))
            this.bind(AstNode.name_of(n))
>>>NEW
            this.bind_each_child(n)
SPEC

run "c36 initializer_of answers a BindingElement" <<SPEC
FILE $A
<<<OLD
            when be: BindingElement
                return be.initializer
>>>NEW
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl35-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl35-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl35-final.log | head -30
  exit 1
fi
