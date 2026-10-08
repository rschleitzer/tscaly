#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice34.sh — the slice-34 control battery, eighteen of them.
#
# Slice 34 is the FUNCTION-LIKE heads: the function type and the constructor
# type on one side, the function expression and the arrow on the other. Two arms
# upstream, four kinds, and they are the heads of both histograms after slice 33.
#
# ★★★ MOST OF WHAT THESE ROWS MEASURE IS NOT THE ARMS' OWN CONTENT. Until this
# slice each of the four kinds reported and RETURNED, so the whole subtree under
# it was never walked — a body's statements, a signature's parameters and type
# parameters, every declaration in either. That is why c1/c9/c10 move a matched
# count far larger than the symbols the arms themselves declare, and it is the
# thing to keep in mind when reading them: an arrow function anywhere in a file
# parked the whole file.
#
# ★★★ AND IT PAYS OFF SLICE 33's DEBT. Two rows of that battery (c23, c24 — the
# IIFE reorder and the SkipParentheses under it) were UNGATED with the verdict
# *unreachable*, for the reason stated in its table: the callee of an IIFE is a
# function expression or an arrow, and both of those `bind` arms were unported,
# so the unit reported either way and the two orders produced the same dump. They
# are c15/c16/c17 here and all three are RED. §3.5cc's rule — the slice that
# lifts a condition owns every claim resting on it — read from the other end: the
# slice that lifts it must also COLLECT.
#
# ★★ The order fixtures follow slice 33's discipline exactly, and for the reason
# it found: tests/oracle/symbols.go numbers symbols IN WALK ORDER, so the
# sequence the binder CREATES them in is invisible in the s section. What carries
# bind order is the B section, a bind-order append of the bind diagnostics — so
# each IIFE fixture puts `eval = <n>` inside the callee and `arguments = <n>` in
# the argument list, and the two TS1100s in the B section are the witness.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice34.sh 2>&1 | tee /tmp/battery34.log
#
# 1 baseline + 18 controls + 1 verifying run = 20 runs, about 10 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.1/tscaly/binder.scaly

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

# ── the four arms exist at all ───────────────────────────────────────────────
#
# Each REPORTS rather than silently falling through to the default arm: slice
# 32's c1 is why (ctl.sh's header has the account). Reporting is the pre-slice
# behaviour exactly, so the row measures what the arm UNLOCKS and nothing else.
# For these four kinds that is very nearly the whole file, because the pre-slice
# behaviour also stopped the WALK.

run "c1 a FunctionType has a bind arm" <<SPEC
FILE $B
<<<OLD
        if k = KindFunctionType
            this.bind_function_or_constructor_type(n)
>>>NEW
        if k = KindFunctionType
        {
            this.record_unported("bind", k)
            return
        }
SPEC

run "c2 a ConstructorType has one" <<SPEC
FILE $B
<<<OLD
        if k = KindConstructorType
            this.bind_function_or_constructor_type(n)
>>>NEW
        if k = KindConstructorType
        {
            this.record_unported("bind", k)
            return
        }
SPEC

run "c3 a FunctionExpression has one" <<SPEC
FILE $B
<<<OLD
        if k = KindFunctionExpression
            this.bind_function_expression(n)
>>>NEW
        if k = KindFunctionExpression
        {
            this.record_unported("bind", k)
            return
        }
SPEC

run "c4 an ArrowFunction has one" <<SPEC
FILE $B
<<<OLD
        if k = KindArrowFunction
            this.bind_function_expression(n)
>>>NEW
        if k = KindArrowFunction
        {
            this.record_unported("bind", k)
            return
        }
SPEC

# ── bindFunctionOrConstructorType: TWO symbols, and which is which ───────────
#
# The one arm in the binder that builds two symbols for one node and wires one
# into the other's table by hand. Every part of that is dumped: the flags, the
# names, the members table, and — through the `d` lines — which of the two the
# node's own symbol slot ends up holding.

run "c5 the signature symbol has the node as its DECLARATION" <<SPEC
FILE $B
<<<OLD
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)
        this.add_declaration_to_symbol(s, n, SymbolFlagsSignature)
>>>NEW
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)
SPEC

run "c6 its name comes from get_declaration_name — call / new" <<SPEC
FILE $B
<<<OLD
        this.get_declaration_name(n, &nd, &nl)
        if this.is_unported()
            return
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)
>>>NEW
        this.get_declaration_name(n, &nd, &nl)
        if this.is_unported()
            return
        set nl: Binder.internal_name(host, "missing", &nd)
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)
SPEC

run "c7 the signature symbol's FLAG is Signature" <<SPEC
FILE $B
<<<OLD
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)
        this.add_declaration_to_symbol(s, n, SymbolFlagsSignature)
>>>NEW
        let s this.new_symbol(SymbolFlagsMethod, nd, nl)
        this.add_declaration_to_symbol(s, n, SymbolFlagsMethod)
SPEC

run "c8 the type literal is a DECLARATION of this node" <<SPEC
FILE $B
<<<OLD
        this.add_declaration_to_symbol(tls, n, SymbolFlagsTypeLiteral)
        let members Symbol.get_members(host, tls)
>>>NEW
        let members Symbol.get_members(host, tls)
SPEC

run "c9 the type literal's name is the internal type" <<SPEC
FILE $B
<<<OLD
        let tl Binder.internal_name(host, "type", &td)
        let tls this.new_symbol(SymbolFlagsTypeLiteral, td, tl)
>>>NEW
        let tl Binder.internal_name(host, "object", &td)
        let tls this.new_symbol(SymbolFlagsTypeLiteral, td, tl)
SPEC

run "c10 the signature is the type literal's sole MEMBER" <<SPEC
FILE $B
<<<OLD
        let members Symbol.get_members(host, tls)
        SymbolTable.set_entry(host, members, s.name_data, s.name_len, s)
>>>NEW
        let members Symbol.get_members(host, tls)
SPEC

# ★★★ The row that says which symbol the NODE ends up carrying. Neither call
# declares into a table, so the second add_declaration_to_symbol simply
# overwrites the node's symbol slot — the reference's order makes that the TYPE
# LITERAL, and swapping the two calls is the only way to ask whether that is
# transcribed or assumed.
run "c11 the type literal is added SECOND, so it owns the node's symbol slot" <<SPEC
FILE $B
<<<OLD
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)
        this.add_declaration_to_symbol(s, n, SymbolFlagsSignature)

        var td null as pointer[char]
        let tl Binder.internal_name(host, "type", &td)
        let tls this.new_symbol(SymbolFlagsTypeLiteral, td, tl)
        this.add_declaration_to_symbol(tls, n, SymbolFlagsTypeLiteral)
>>>NEW
        let s this.new_symbol(SymbolFlagsSignature, nd, nl)

        var td null as pointer[char]
        let tl Binder.internal_name(host, "type", &td)
        let tls this.new_symbol(SymbolFlagsTypeLiteral, td, tl)
        this.add_declaration_to_symbol(tls, n, SymbolFlagsTypeLiteral)
        this.add_declaration_to_symbol(s, n, SymbolFlagsSignature)
SPEC

# ── bindFunctionExpression: the name, and the one diagnostic ─────────────────

run "c12 an unnamed function expression takes the internal function name" <<SPEC
FILE $B
<<<OLD
        if named = false
            set nl: Binder.internal_name(host, "function", &nd)
>>>NEW
        if named = false
            set nl: Binder.internal_name(host, "type", &nd)
SPEC

run "c13 a NAMED function expression takes its own name" <<SPEC
FILE $B
<<<OLD
                set nd: AstNode.identifier_text_of(name)
                set nl: AstNode.identifier_text_length_of(name)
                set named: true
>>>NEW
                set nd: AstNode.identifier_text_of(name)
                set nl: AstNode.identifier_text_length_of(name)
SPEC

run "c14 the symbol's flag is Function" <<SPEC
FILE $B
<<<OLD
        this.bind_anonymous_declaration(n, SymbolFlagsFunction, nd, nl)
>>>NEW
        this.bind_anonymous_declaration(n, SymbolFlagsClass, nd, nl)
SPEC

run "c15 checkStrictModeFunctionName runs on a named function expression" <<SPEC
FILE $B
<<<OLD
                this.check_strict_mode_function_name(n)
>>>NEW
                ; the control removed the only diagnostic of this arm
SPEC

# ★ The kind test itself. An arrow has no name SLOT, so name_of answers null for
# one and the guarded block is skipped anyway — this is *indistinguishable* by
# construction, and the row exists to say so rather than to be missing.
run "c16 the kind test in front of the name lookup" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(n) = KindFunctionExpression
        {
            let name AstNode.name_of(n)
>>>NEW
        if true
        {
            let name AstNode.name_of(n)
SPEC

# ── slice 33's two unreachable rows, collected ───────────────────────────────
#
# c23 and c24 of controls-slice33.sh, verbatim, now that the callee of an IIFE
# has a bind arm. The claim each breaks belongs to slice 33's
# bind_call_expression_flow; the reason it can be MEASURED belongs to this slice.

run "c17 the IIFE reorder — arguments before the callee (was slice 33's c23)" <<SPEC
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

run "c18 SkipParentheses in the IIFE test (was slice 33's c24)" <<SPEC
FILE $B
<<<OLD
        let callee Parser.skip_parentheses(AstNode.expression_of(n))
>>>NEW
        let callee AstNode.expression_of(n)
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl34-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl34-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl34-final.log | head -30
  exit 1
fi
