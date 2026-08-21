#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice39.sh — the slice-39 control battery, seventeen of them.
#
# Slice 39 is the PARAMETER PROPERTY: bindParameter's second half, where
# `constructor(public a: number)` declares a class property beside the parameter —
# one node owning two symbols in two tables, which nothing else in the binder
# does.
#
# ★★★ SIX GROUPS, BECAUSE THE ARM MAKES SIX DIFFERENT KINDS OF CLAIM.
#
#   c1        what the slice UNLOCKS: the arm at all.
#
#   c2..c3    IsParameterPropertyDeclaration is a CONJUNCTION, and each half is
#             measured by removing it — a widening control, deliberately: the row
#             says how many units depend on that half being asked. Without the
#             modifier test every constructor parameter declares a property;
#             without the parent test every parameter carrying an accessibility
#             modifier does, wherever it stands.
#
#   c4..c8    the five modifiers, one row each. ModifierFlagsParameterProperty-
#             Modifier is AccessibilityModifier | Readonly | Override, and a
#             fixture carrying all five is worth nothing until a control aims at
#             one of them (§3.5ap).
#
#   c9..c11   WHERE the property goes: the table (members, not exports), the
#             class (off the TREE, not off the container register) and the parent
#             symbol.
#
#   c12..c14  the flags and the excludes: Property, the Optional bit behind the
#             question token, and PropertyExcludes — whose whole content is which
#             collisions merge and which report.
#
#   c15       the ORDER. Both declarations write `node.symbol`, so the parameter
#             node ends up owning the PROPERTY's symbol; declaring them the other
#             way round is a well-formed wrong answer.
#
#   c16..c17  the two rows expected UNGATED with an UNREACHABILITY argument
#             rather than a shrug (§3.5v): the predicate's KIND conjunct, which
#             bind_parameter's own case label already decides, and the
#             class-symbol null test, since every path into a class member has
#             been through bindClassLikeDeclaration, which sets that slot or
#             reports. ★c3 is the argument for keeping the second one anyway —
#             with the parent test gone, the very same marker FIRES.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice39.sh 2>&1 | tee /tmp/battery39.log
#
# 1 baseline + 17 controls + 1 verifying run = 19 runs, about 7 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.0/tscaly/binder.scaly

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

run "c1 a parameter property declares into the class at all" <<SPEC
FILE $B
<<<OLD
        if this.is_parameter_property_declaration(n) = false
            return
        let class_declaration AstNode.parent_node_of(AstNode.parent_node_of(n))
        let cs AstNode.symbol_of(class_declaration)
        if cs = null
        {
            this.record_unported("parameter-property-class-symbol", 0)
            return
        }
        var flags: int SymbolFlagsProperty
        if AstNode.parameter_question_token_of(n) <> null
            set flags: flags | SymbolFlagsOptional
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
>>>NEW
        if this.is_parameter_property_declaration(n)
            this.record_unported("parameter-property", 0)
SPEC

# ── group 2: the conjunction's two halves ────────────────────────────────────

run "c2 the MODIFIER half is asked (without it every constructor parameter is a property)" <<SPEC
FILE $B
<<<OLD
        let f this.modifier_flags(n)
>>>NEW
        let f: int ModifierFlagsPublic
SPEC

run "c3 the PARENT half is asked (without it a modifier anywhere declares a property)" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(p) <> KindConstructor
            return false
>>>NEW
SPEC

# ── group 3: the five modifiers, one row each ────────────────────────────────

run "c4 public makes a parameter a property" <<SPEC
FILE $B
<<<OLD
        if (f & ModifierFlagsPublic) <> 0
            return true
>>>NEW
SPEC

run "c5 private does" <<SPEC
FILE $B
<<<OLD
        if (f & ModifierFlagsPrivate) <> 0
            return true
>>>NEW
SPEC

run "c6 protected does" <<SPEC
FILE $B
<<<OLD
        if (f & ModifierFlagsProtected) <> 0
            return true
>>>NEW
SPEC

run "c7 readonly does" <<SPEC
FILE $B
<<<OLD
        if (f & ModifierFlagsReadonly) <> 0
            return true
>>>NEW
SPEC

run "c8 override does" <<SPEC
FILE $B
<<<OLD
        if (f & ModifierFlagsOverride) <> 0
            return true
>>>NEW
SPEC

# ── group 4: where the property goes ─────────────────────────────────────────

run "c9 the property goes into the class's MEMBERS, not its exports" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
>>>NEW
        this.declare_symbol(Symbol.get_exports(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
SPEC

run "c10 the class is read off the TREE, not off the container register" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
>>>NEW
        this.declare_symbol_and_add_to_symbol_table(n, flags, SymbolFlagsPropertyExcludes)
SPEC

run "c11 the property symbol's PARENT is the class symbol" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
>>>NEW
        this.declare_symbol(Symbol.get_members(host, cs), null as pointer[Symbol], n, flags, SymbolFlagsPropertyExcludes)
SPEC

# ── group 5: the flags and the excludes ──────────────────────────────────────

run "c12 the symbol carries SymbolFlagsProperty" <<SPEC
FILE $B
<<<OLD
        var flags: int SymbolFlagsProperty
        if AstNode.parameter_question_token_of(n) <> null
>>>NEW
        var flags: int SymbolFlagsNone
        if AstNode.parameter_question_token_of(n) <> null
SPEC

run "c13 the question token adds SymbolFlagsOptional" <<SPEC
FILE $B
<<<OLD
        if AstNode.parameter_question_token_of(n) <> null
            set flags: flags | SymbolFlagsOptional
>>>NEW
SPEC

run "c14 the excludes are PropertyExcludes" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
>>>NEW
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsNone)
SPEC

# ── group 6: the order, and the unreachable marker ───────────────────────────

run "c15 the PARAMETER is declared first, so the PROPERTY owns node.symbol" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsFunctionScopedVariable, SymbolFlagsParameterExcludes)
        if this.is_unported()
            return
        if this.is_parameter_property_declaration(n) = false
            return
        let class_declaration AstNode.parent_node_of(AstNode.parent_node_of(n))
        let cs AstNode.symbol_of(class_declaration)
        if cs = null
        {
            this.record_unported("parameter-property-class-symbol", 0)
            return
        }
        var flags: int SymbolFlagsProperty
        if AstNode.parameter_question_token_of(n) <> null
            set flags: flags | SymbolFlagsOptional
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
>>>NEW
        if this.is_parameter_property_declaration(n)
        {
            let class_declaration AstNode.parent_node_of(AstNode.parent_node_of(n))
            let cs AstNode.symbol_of(class_declaration)
            if cs = null
            {
                this.record_unported("parameter-property-class-symbol", 0)
                return
            }
            var flags: int SymbolFlagsProperty
            if AstNode.parameter_question_token_of(n) <> null
                set flags: flags | SymbolFlagsOptional
            this.declare_symbol(Symbol.get_members(host, cs), cs, n, flags, SymbolFlagsPropertyExcludes)
        }
        this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsFunctionScopedVariable, SymbolFlagsParameterExcludes)
SPEC

run "c16 the KIND conjunct — expected UNGATED, unreachable (bind_parameter's arm decides it)" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(n) <> KindParameter
            return false
>>>NEW
SPEC

run "c17 the class-symbol null test — expected UNGATED, unreachable" <<SPEC
FILE $B
<<<OLD
        if cs = null
        {
            this.record_unported("parameter-property-class-symbol", 0)
            return
        }
>>>NEW
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl39-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl39-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl39-final.log | head -30
  exit 1
fi
