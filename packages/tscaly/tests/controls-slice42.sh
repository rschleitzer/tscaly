#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice42.sh — the slice-42 control battery, eighteen of them.
#
# Slice 42 is `this.a = x`, the fourth assignment-declaration kind and the only
# one that declares into a CLASS: bindThisPropertyAssignment, plus the two flags
# of declareSymbolEx that no other caller in the binder passes —
# isReplaceableByMethod and isComputedName.
#
# ★★★ FIVE GROUPS, AND THE LAST ONE IS THE REASON THE SLICE WAITED.
#
#   c1        what the slice UNLOCKS: the arm at all.
#
#   c2..c5    the THREE GUARDS plus the exemption. JavaScript only, not a private
#             name, a live `this` register — and the two function kinds that are
#             let through the unhandled case on purpose. Each is an ABSENCE in the
#             dump, so each needs a row: a guard that does not fire and a guard
#             that is not there look identical from the output.
#
# ★★★ c4 INVERTS the null guard instead of removing it, and the reason is worth
# more than the row: REMOVING it does not produce a deviation, it produces a
# CRASH. `AstNode.kind_of` does not test for null — nothing in this port's
# accessors is obliged to — so the unhandled-case tail two lines down would
# dereference the null register on the first top-level `this.a = 1` in the corpus.
# A control that counts crashes has stopped measuring the claim, so the row states
# the half that can be measured (the test is for null, not for presence) and the
# other half is stated here: the guard is load-bearing because the tail derefs.
#
# ★★★ c2 CAME BACK UNGATED, AND IT IS A FINDING RATHER THAN A WEAK ROW: the arm's
# own `IsInJSFile` guard is unreachable-as-false, because the CLASSIFIER already
# is one. `getAssignmentDeclarationKind` returns ThisProperty only from inside
# `if IsInJSFile(bin.Left)`, so a TypeScript `this.a = 1` never reaches this arm at
# all and the guard upstream writes is a second lock on the same door. Ported
# because the reference has it; measured, so that nobody has to guess which of the
# two does the work. ★The fixture that shows the OUTCOME
# (binder_this_property_typescript.ts) is still worth having — it is just evidence
# about the classifier, not about the guard.
#
# ★★ AND c14/c17's 14 IS NOT THE RULE FIRING FOURTEEN TIMES. The replaceable mark
# is a symbol FLAG and the dump prints flags, so dropping the write (c14) or the
# argument (c17) changes fourteen units' output without any arm having to fire.
# What measures the rule's BEHAVIOUR is c15 and c16, at two units each. A row that
# moves a lot is not thereby a row about a lot.
#
#   c6..c7    the TABLE, which is the arm's whole point: the class symbol is the
#             this-container's PARENT, and static-vs-instance chooses exports over
#             members. ★Both patch get_this_class_and_symbol_table, whose only
#             other caller (lookup_entity, in the deferred pass) always sees a null
#             register and therefore cannot be affected — so unlike slice 41's
#             c15/c16 these rows really are scoped to this arm, and that is an
#             argument from the pass's own verdict rather than a hope.
#
#   c8..c13   the FLAGS and the NAME on both paths: Assignment on the static-named
#             one and NOT on the dynamic one, the dynamic test being asked at all
#             (both directions), the late-bound record, and the `computed` name.
#
#   c14..c18  isReplaceableByMethod, the JavaScript constructor-property rule.
#             The write on a fresh symbol, then each of the two arms that read it,
#             then the flag being passed at all. ★It is the one rule here whose
#             every effect is an absence or an orphan — no declaration added, no
#             diagnostic, a symbol in no table — which is why five rows go to it.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice42.sh 2>&1 | tee /tmp/battery42.log
#
# 1 baseline + 18 controls + 1 verifying run = 20 runs, about 11 minutes on an
# idle box. ★If it takes hours, read §3.5ck before suspecting the battery.

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

# ── group 1: what the slice unlocks ──────────────────────────────────────────

run "c1 a this-property assignment is bound at all" <<SPEC
FILE $B
<<<OLD
            if adk = JSDeclarationKindThisProperty
                this.bind_this_property_assignment(n)
>>>NEW
            if adk = JSDeclarationKindThisProperty
                this.record_unported("assignment-declaration", adk)
SPEC

# ── group 2: the guards ──────────────────────────────────────────────────────

run "c2 the JavaScript guard (dropped: a TypeScript class declares too)" <<SPEC
FILE $B
<<<OLD
        if Parser.is_in_js_file(n) = false
            return

        let left AstNode.binary_left_of(n)
>>>NEW
        let left AstNode.binary_left_of(n)
SPEC

run "c3 the PRIVATE-name guard (dropped: this.#x declares a second time)" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(left) = KindPropertyAccessExpression
        {
            if AstNode.kind_of(AstNode.name_of(left)) = KindPrivateIdentifier
                return
        }
>>>NEW
SPEC

run "c4 the this-register guard tests for NULL, not for presence" <<SPEC
FILE $B
<<<OLD
        if this_container = null
            return

        var class_symbol null as pointer[Symbol]
>>>NEW
        if this_container <> null
            return

        var class_symbol null as pointer[Symbol]
SPEC

run "c5 the two function kinds are EXEMPT from the unhandled case" <<SPEC
FILE $B
<<<OLD
        let tk AstNode.kind_of(this_container)
        if tk = KindFunctionDeclaration
            return
        if tk = KindFunctionExpression
            return
        this.record_unported("this-property-constructor-function", tk)
>>>NEW
        let tk AstNode.kind_of(this_container)
        this.record_unported("this-property-constructor-function", tk)
SPEC

# ── group 3: the table ───────────────────────────────────────────────────────

run "c6 the class symbol is the this-container's PARENT (scoped: see the header)" <<SPEC
FILE $B
<<<OLD
        let cs AstNode.symbol_of(AstNode.parent_node_of(this_container))
>>>NEW
        let cs AstNode.symbol_of(this_container)
SPEC

run "c7 a STATIC member's assignment goes to exports, not members (likewise)" <<SPEC
FILE $B
<<<OLD
        if this.is_static(this_container)
            return Symbol.get_exports(host, cs)
        Symbol.get_members(host, cs)
>>>NEW
        Symbol.get_members(host, cs)
SPEC

# ── group 4: the flags and the name ──────────────────────────────────────────

run "c8 the static-named path carries Assignment beside Property" <<SPEC
FILE $B
<<<OLD
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, SymbolFlagsNone, true, false)
>>>NEW
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, false)
SPEC

run "c9 the DYNAMIC path does NOT carry Assignment" <<SPEC
FILE $B
<<<OLD
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, true)
>>>NEW
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, SymbolFlagsNone, true, true)
SPEC

run "c10 the dynamic test is asked (hardwired false: every name is static)" <<SPEC
FILE $B
<<<OLD
            if this.has_dynamic_name(n)
            {
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, true)
>>>NEW
            if false
            {
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, true)
SPEC

run "c11 ... and from the other side: every name takes the computed path" <<SPEC
FILE $B
<<<OLD
            if this.has_dynamic_name(n)
            {
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, true)
>>>NEW
            if true
            {
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, true)
SPEC

run "c12 the late-bound assignment record is written" <<SPEC
FILE $B
<<<OLD
                this.add_late_bound_assignment_declaration_to_symbol(n, class_symbol)
>>>NEW
SPEC

run "c13 isComputedName names the symbol 'computed'" <<SPEC
FILE $B
<<<OLD
        if is_computed_name
            set name_len: Binder.internal_name(host, "computed", &name_data)
>>>NEW
        if is_computed_name
            set name_len: Binder.internal_name(host, "missing", &name_data)
SPEC

# ── group 5: the constructor-property rule ───────────────────────────────────

run "c14 the replaceable MARK is written on a fresh symbol" <<SPEC
FILE $B
<<<OLD
                if is_replaceable_by_method
                    set s.flags: s.flags | SymbolFlagsReplaceableByMethod
>>>NEW
SPEC

run "c15 arm ONE: the later constructor property loses, adding no declaration" <<SPEC
FILE $B
<<<OLD
                var replaceable_loses false
                if is_replaceable_by_method
                {
                    if (s.flags & SymbolFlagsReplaceableByMethod) = 0
                        set replaceable_loses: true
                }
                if replaceable_loses
                    return s
>>>NEW
SPEC

run "c16 arm TWO: a conflicting MARKED symbol is discarded for a fresh one" <<SPEC
FILE $B
<<<OLD
                    if (s.flags & SymbolFlagsReplaceableByMethod) <> 0
                    {
                        set s: this.new_symbol(SymbolFlagsNone, name_data, name_len)
                        SymbolTable.set_entry(host, table, name_data, name_len, s)
                    }
                    else
                    {
>>>NEW
                    if (s.flags & SymbolFlagsNone) <> 0
                    {
                        set s: this.new_symbol(SymbolFlagsNone, name_data, name_len)
                        SymbolTable.set_entry(host, table, name_data, name_len, s)
                    }
                    else
                    {
SPEC

run "c17 the static-named call passes isReplaceableByMethod" <<SPEC
FILE $B
<<<OLD
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, SymbolFlagsNone, true, false)
>>>NEW
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, SymbolFlagsNone, false, false)
SPEC

run "c18 the DYNAMIC call passes it too" <<SPEC
FILE $B
<<<OLD
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, true, true)
>>>NEW
                this.declare_symbol_ex(table, class_symbol, n, SymbolFlagsProperty, SymbolFlagsNone, false, true)
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl42-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl42-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl42-final.log | head -30
  exit 1
fi
