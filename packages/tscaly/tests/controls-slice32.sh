#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice32.sh — the slice-32 control battery, fifteen of them.
#
# Slice 32 is the OBJECT LITERAL family: the literal itself (an anonymous
# container, the fourth and last one whose members declare into a `members`
# table), its two property kinds, and the shared assignment-pattern case label
# of bindChildren.
#
# ★★★ TWO ROWS ARE EXPECTED UNGATED AND BOTH ARE THE POINT OF THE SLICE, so read
# them before the reds. c13 routes the assignment-pattern arm back into the
# DEFAULT arm and nothing moves — because bindEachChild is exactly what the
# default arm does, and the reference's arm differs from it only in restoring
# `inAssignmentPattern` BEFORE the descent instead of after. That field has one
# reader in binder.go, bindDestructuringAssignmentFlow, reached only from the
# BinaryExpression arm, which is unported: §3.5v's *unmodelled*. This arm was
# the stated reason to postpone the object literal for two slices, and its cost,
# measured, is zero. c14 is the same verdict one level down — the extra
# container bit a method of an object literal carries is read only by the flow
# half.
#
# ★★ c10 and c11 are the two halves of "the members land in the right table",
# and they fail differently on purpose: c10 breaks the CONTAINER FLAG (the
# literal stops being a container, so its properties file into the enclosing
# scope's table) and c11 breaks the TABLE CHOICE (the container is still the
# literal, and declare_symbol_and_add_to_symbol_table falls out to its
# unreachable-marker instead). One is a wrong answer, the other an admitted one.
#
# ★ c5 is the row worth aiming a fixture at rather than trusting: an object
# literal's own PropertyExcludes never collide with another property — two
# `a:` merge into one symbol, which is why `{ a: 1, a: 2 }` produces no
# diagnostic anywhere — so the only witness is a property standing beside a
# METHOD of the same name (binder_object_property_excludes.ts).
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice32.sh 2>&1 | tee /tmp/battery32.log
#
# 1 baseline + 15 controls + 1 verifying run = 17 runs, about 15 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.2/tscaly/binder.scaly

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

# ── the literal's own symbol ─────────────────────────────────────────────────

# ★★★ c1 REPORTS instead of simply not declaring, and the first draft is why.
# `if false` leaves the literal a CONTAINER with no symbol, so
# declare_symbol_and_add_to_symbol_table's members arm asks Symbol.get_members of
# a null and the dumper dies: RED 131, of which 130 read `our dumper exited -11`.
# That is a count of CRASHES, not of disagreements — a control has to break its
# claim and nothing else, and removing a declaration that later code is entitled
# to assume breaks two things. Reporting is the pre-slice behaviour exactly, so
# the row measures what the arm UNLOCKS.
run "c1 an ObjectLiteralExpression has a bind arm at all" <<SPEC
FILE $B
<<<OLD
        if k = KindObjectLiteralExpression
            this.bind_object_literal_expression(n)
>>>NEW
        if k = KindObjectLiteralExpression
            this.record_unported("bind", k)
SPEC

run "c2 the anonymous symbol's NAME is 'object', not the type literal's 'type'" <<SPEC
FILE $B
<<<OLD
        let nl Binder.internal_name(host, "object", &nd)
>>>NEW
        let nl Binder.internal_name(host, "type", &nd)
SPEC

run "c3 the anonymous symbol's FLAG is ObjectLiteral" <<SPEC
FILE $B
<<<OLD
        this.bind_anonymous_declaration(n, SymbolFlagsObjectLiteral, nd, nl)
>>>NEW
        this.bind_anonymous_declaration(n, SymbolFlagsTypeLiteral, nd, nl)
SPEC

run "c4 the internal name carries the 0xFE PREFIX" <<SPEC
FILE $B
<<<OLD
        let nl Binder.internal_name(host, "object", &nd)
>>>NEW
        let nl Binder.internal_name_unprefixed(host, "object", &nd)
SPEC

# ── the two property kinds ───────────────────────────────────────────────────

run "c5 a PropertyAssignment declares a symbol" <<SPEC
FILE $B
<<<OLD
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
        if false
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
SPEC

run "c6 a SHORTHAND property declares a symbol too" <<SPEC
FILE $B
<<<OLD
        if k = KindShorthandPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
        if false
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
SPEC

run "c7 a property's flag is Property, not Method" <<SPEC
FILE $B
<<<OLD
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsMethod, SymbolFlagsPropertyExcludes)
SPEC

run "c8 a property EXCLUDES the values it may not stand beside" <<SPEC
FILE $B
<<<OLD
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsNone)
SPEC

run "c15 an object literal's property carries NO optional flag" <<SPEC
FILE $B
<<<OLD
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
>>>NEW
        if k = KindPropertyAssignment
            this.bind_property_or_method_or_accessor(n, SymbolFlagsProperty | Binder.optional_symbol_flag_for_node(n), SymbolFlagsPropertyExcludes)
SPEC

run "c9 an object-literal METHOD excludes every VALUE, not just other methods" <<SPEC
FILE $B
<<<OLD
        if Binder.is_object_literal_method(n)
            set excludes: SymbolFlagsValue
>>>NEW
        if false
            set excludes: SymbolFlagsValue
SPEC

# ── the table the members land in ────────────────────────────────────────────

run "c10 the object literal is a CONTAINER" <<SPEC
FILE $B
<<<OLD
        if k = KindObjectLiteralExpression
            return ContainerFlagsIsContainer
>>>NEW
        if k = KindObjectLiteralExpression
            return ContainerFlagsNone
SPEC

run "c11 its members declare into the symbol's MEMBERS table" <<SPEC
FILE $B
<<<OLD
        if ck = KindObjectLiteralExpression
            return true
>>>NEW
        if false
            return true
SPEC

# ── the traversal ────────────────────────────────────────────────────────────

run "c12 the four kinds of the shared label are BOUND rather than reported" <<SPEC
FILE $B
<<<OLD
        if Binder.binds_children_as_assignment_pattern_operand(k)
        {
            this.bind_each_child(n)
            return
        }
>>>NEW
        if Binder.binds_children_as_assignment_pattern_operand(k)
        {
            this.record_unported("bind-children", k)
            return
        }
SPEC

run "c13 the assignment-pattern arm is the DEFAULT arm — expected UNGATED" <<SPEC
FILE $B
<<<OLD
        if Binder.binds_children_as_assignment_pattern_operand(k)
>>>NEW
        if false
SPEC

run "c14 an object-literal method's extra container bit — expected UNGATED" <<SPEC
FILE $B
<<<OLD
        let pk AstNode.kind_of(p)
        if pk = KindObjectLiteralExpression
            return true
>>>NEW
        let pk AstNode.kind_of(p)
        if false
            return true
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl32-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl32-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl32-final.log | head -30
  exit 1
fi
