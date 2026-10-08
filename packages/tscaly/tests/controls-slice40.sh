#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice40.sh — the slice-40 control battery, eighteen of them.
#
# Slice 40 is the BINDING-PATTERN arm of bindParameter, the sibling of the one
# slice 39 ported: a destructured parameter has no name to be known by, so the
# binder mints one from the parameter's POSITION in its parent's list — `__0`,
# `__1`, … — and declares it anonymously, into no table at all.
#
# ★★★ SEVEN GROUPS, BECAUSE THE ARM MAKES SEVEN DIFFERENT KINDS OF CLAIM.
#
#   c1        what the slice UNLOCKS: the arm at all.
#
#   c2..c5    the ROUTE. The if/else is a two-way choice and both directions are
#             measured — every parameter anonymous, and no parameter anonymous —
#             followed by the two things that make the anonymous route what it
#             is: bindAnonymousDeclaration rather than the table-adding one, and
#             the flags it carries.
#
#   c6..c11   the NAME, which is where all the arithmetic is. The prefix's two
#             bytes, the returned LENGTH, the index being read at all, the digit
#             COUNT, the digit ORDER, and the list being the PARENT's.
#
#   c12       the FALL-THROUGH, and it is the row this slice exists to make
#             honest: slice 39 wrote the warning at the `return` this arm
#             replaces, because the reference's parameter-property test sits
#             AFTER the if/else.
#
#   c13..c15  the accessor this slice WIDENED. parameters_of used to cover the
#             kinds getFunctionLikeHost can answer, and a FunctionType is not one
#             of them; each arm gets a row, and the third row is the not-found
#             marker itself — expected UNGATED, since with both arms present no
#             index is ever negative.
#
#   c16..c17  IsBindingPattern's two kinds. ★These two are NOT scoped to this
#             arm: is_binding_pattern also serves the variable-declaration and
#             binding-element arm, so each row counts both callers. Labelled
#             rather than dressed up, for the reason §3.5 keeps insisting on —
#             a row whose scope is wider than its title is a wrong number
#             wearing a right one's clothes.
#
#   c18       ...and that is why the guard needs a row of its own, appended after
#             the battery's first run measured c15 as UNGATED. The claim is a
#             CONJUNCTION — a negative index AND no guard — and this harness
#             patches one contiguous block of one file, so the row states it as
#             one: the guard is replaced by a hardwired `0 - 1`. ★Read it against
#             c11, which is the same negative index WITH the guard: there the 18
#             units are an honest unported record, here they are eighteen wrong
#             NAMES. That pair is the guard's whole justification, and it is
#             measured rather than argued.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice40.sh 2>&1 | tee /tmp/battery40.log
#
# 1 baseline + 18 controls + 1 verifying run = 20 runs, about 10 minutes on an idle
# box. ★It took FIVE HOURS on the box that first ran it, and the reason is
# §3.5ck: a stage-2 artifact tree had just been created and deleted under
# packages/, and the machine's own indexer and endpoint-protection agent were
# still chewing through it at load average 12. A control's VERDICT is a count and
# survives that; its timing does not.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.1/tscaly/binder.scaly
A=packages/tscaly/0.1.1/tscaly/ast.scaly

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

# ── group 1: what the slice unlocks ──────────────────────────────────────────

run "c1 a destructured parameter is bound at all" <<SPEC
FILE $B
<<<OLD
            let index Binder.parameter_index(n)
            if index < 0
            {
                this.record_unported("parameter-index-not-found", 0)
                return
            }
            var nd null as pointer[char]
            let nl Binder.anonymous_parameter_name(host, index, &nd)
            this.bind_anonymous_declaration(n, SymbolFlagsFunctionScopedVariable, nd, nl)
>>>NEW
            this.record_unported("parameter-binding-pattern", 0)
            return
SPEC

# ── group 2: the route ───────────────────────────────────────────────────────

run "c2 the binding-pattern test is asked (widening: every parameter anonymous)" <<SPEC
FILE $B
<<<OLD
        var pattern false
        if name <> null
            set pattern: Binder.is_binding_pattern(name)
>>>NEW
        var pattern true
        if name <> null
            set pattern: true
SPEC

run "c3 ... and from the other side: no parameter takes the anonymous route" <<SPEC
FILE $B
<<<OLD
        var pattern false
        if name <> null
            set pattern: Binder.is_binding_pattern(name)
>>>NEW
        var pattern false
        if name <> null
            set pattern: false
SPEC

run "c4 the anonymous route is bind_anonymous_declaration, i.e. NO table" <<SPEC
FILE $B
<<<OLD
            this.bind_anonymous_declaration(n, SymbolFlagsFunctionScopedVariable, nd, nl)
>>>NEW
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsFunctionScopedVariable, SymbolFlagsParameterExcludes)
SPEC

run "c5 the anonymous symbol carries FunctionScopedVariable" <<SPEC
FILE $B
<<<OLD
            this.bind_anonymous_declaration(n, SymbolFlagsFunctionScopedVariable, nd, nl)
>>>NEW
            this.bind_anonymous_declaration(n, SymbolFlagsNone, nd, nl)
SPEC

# ── group 3: the name ────────────────────────────────────────────────────────

run "c6 the prefix is two ASCII underscores, not the 0xFE internal one" <<SPEC
FILE $B
<<<OLD
        set *buf: "_" as char
        set *(buf + 1): "_" as char
>>>NEW
        set *buf: 0xFE as char
        set *(buf + 1): "_" as char
SPEC

run "c7 the returned LENGTH counts the prefix" <<SPEC
FILE $B
<<<OLD
        set *out_data: buf
        digits + 2
    }
>>>NEW
        set *out_data: buf
        digits + 1
    }
SPEC

run "c8 the INDEX is read (hardwired 0: every pattern of one file is __0)" <<SPEC
FILE $B
<<<OLD
            if *(params.get_buffer() + i) = n
                return i
>>>NEW
            if *(params.get_buffer() + i) = n
                return 0
SPEC

run "c9 the digit COUNT is measured (hardwired 1)" <<SPEC
FILE $B
<<<OLD
        var digits 1
        var rest index / 10
        while rest > 0
        {
            set digits: digits + 1
            set rest: rest / 10
        }
>>>NEW
        var digits 1
SPEC

run "c10 the digits are written most-significant-FIRST" <<SPEC
FILE $B
<<<OLD
        var value index
        var i digits
        while i > 0
        {
            set *(buf + 1 + i): ((("0" as char) as int) + (value % 10)) as char
            set value: value / 10
            set i: i - 1
        }
>>>NEW
        var value index
        var i 1
        while i <= digits
        {
            set *(buf + 1 + i): ((("0" as char) as int) + (value % 10)) as char
            set value: value / 10
            set i: i + 1
        }
SPEC

run "c11 the list is the PARENT's, not the parameter's own" <<SPEC
FILE $B
<<<OLD
        let params AstNode.parameters_of(AstNode.parent_node_of(n))
>>>NEW
        let params AstNode.parameters_of(n)
SPEC

# ── group 4: the fall-through slice 39 asked for ─────────────────────────────

run "c12 the arm FALLS THROUGH into the parameter-property arm" <<SPEC
FILE $B
<<<OLD
            this.bind_anonymous_declaration(n, SymbolFlagsFunctionScopedVariable, nd, nl)
>>>NEW
            this.bind_anonymous_declaration(n, SymbolFlagsFunctionScopedVariable, nd, nl)
            return
SPEC

# ── group 5: the accessor this slice widened ─────────────────────────────────

run "c13 parameters_of's FunctionType arm" <<SPEC
FILE $A
<<<OLD
            when ft: FunctionType
                return ft.parameters
>>>NEW
SPEC

run "c14 parameters_of's ConstructorType arm" <<SPEC
FILE $A
<<<OLD
            when ct: ConstructorType
                return ct.parameters
>>>NEW
SPEC

run "c15 the not-found marker — expected UNGATED, and c13 is why it stays" <<SPEC
FILE $B
<<<OLD
            if index < 0
            {
                this.record_unported("parameter-index-not-found", 0)
                return
            }
>>>NEW
SPEC

# ── group 6: the two pattern kinds (SHARED with the binding-element arm) ─────

run "c16 IsBindingPattern's ObjectBindingPattern arm (shared: also the variable arm)" <<SPEC
FILE $B
<<<OLD
        if k = KindObjectBindingPattern
            return true
>>>NEW
SPEC

run "c17 IsBindingPattern's ArrayBindingPattern arm (shared: also the variable arm)" <<SPEC
FILE $B
<<<OLD
        if k = KindArrayBindingPattern
            return true
>>>NEW
SPEC

run "c18 the not-found GUARD: without it a negative index becomes a wrong NAME" <<SPEC
FILE $B
<<<OLD
            let index Binder.parameter_index(n)
            if index < 0
            {
                this.record_unported("parameter-index-not-found", 0)
                return
            }
>>>NEW
            let index 0 - 1
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl40-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl40-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl40-final.log | head -30
  exit 1
fi
