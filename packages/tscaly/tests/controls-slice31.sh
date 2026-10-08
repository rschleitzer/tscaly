#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice31.sh — the slice-31 control battery, thirty-seven of them.
#
# Slice 31 is the MODULE DECLARATION, the ENUM that ships with it, and the
# literal TEXT both of them forced into ast.scaly. Three groups of claims, and
# they fail in three different ways, which is why the battery is worth its ten
# minutes:
#
#   the SYMBOL a module declares    — ValueModule against NamespaceModule, and a
#                                     quoted name against a bare one
#   the STATE its body has          — getModuleInstanceState, whose answer is a
#                                     walk over the body and, through an export
#                                     clause, over the scopes ABOVE it
#   the NAME a literal gives        — a declaration named by a string, a number
#                                     or a signed number
#
# ★★★ THE ROW TO READ FIRST IS c35, because it is the one that found a defect
# rather than confirming a claim. `SymbolTable.set_entry` could not REPLACE an
# entry — `set (*p).field: v` is a silent no-op in this compiler, the class
# `scaly/memory/root_pages.scaly` documents from the heap-trace side — and
# declare_symbol's duplicate path called set_entry where the reference does NOT
# re-insert. Two defects that cancelled: fixing the store turned TEN units red at
# once, and removing the line the reference does not have turned them green
# again. Neither could be seen while the other stood. c35 breaks the store and c23
# the caller's answer, so the two halves are measured separately.
#
# ★★ TWO ROWS ARE EXPECTED UNGATED and each names which of §3.5v's four reasons it
# is. c33 (a signed numeric computed name keeps its sign) is *unreachable*: the
# name is computed correctly and the unit then stops at the PrefixUnaryExpression's
# own bind arm, which is unported. c20 (an alias target must be an IDENTIFIER) is
# *indistinguishable*: with the guard gone the lookup compares the string
# literal's EMPTY identifier text against every statement name, matches nothing,
# and falls out to the same Instantiated the guard answers directly.
#
# ★★★ FIVE MORE ROWS WERE UNGATED ON THE FIRST RUN and are RED here, each because
# of one small fixture (c17, c19, c21, c25, c26) — and c21's first fixture could
# not gate anything, because the ModuleBlock walk STOPS at the first instantiated
# child and the variable statement it was aimed at is one, so the export clause was
# never visited. A fixture for a lookup has to make the lookup happen.
#
# ★ c15 (the ModuleBlock walk's STOP) is the row that looks like an optimisation
# and is not: without it a const enum standing AFTER an instantiated statement
# raises the answer to ConstEnumOnly, because that arm assigns unconditionally.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice31.sh 2>&1 | tee /tmp/battery31.log
#
# 1 baseline + 37 controls + 1 verifying run = 39 runs, about 30 minutes.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.1/tscaly/binder.scaly
A=packages/tscaly/0.1.1/tscaly/ast.scaly
P=packages/tscaly/0.1.1/tscaly/parser.scaly

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

# ── the module declaration itself ────────────────────────────────────────────

run "c1 a ModuleDeclaration declares a symbol at all" <<SPEC
FILE $B
<<<OLD
        if k = KindModuleDeclaration
            this.bind_module_declaration(n)
>>>NEW
        if false
            this.bind_module_declaration(n)
SPEC

run "c2 an INSTANTIATED module is a ValueModule, an uninstantiated one a NamespaceModule" <<SPEC
FILE $B
<<<OLD
        if state = ModuleInstanceStateNonInstantiated
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsNamespaceModule, SymbolFlagsNamespaceModuleExcludes)
        else
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsValueModule, SymbolFlagsValueModuleExcludes)
>>>NEW
        if false
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsNamespaceModule, SymbolFlagsNamespaceModuleExcludes)
        else
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsValueModule, SymbolFlagsValueModuleExcludes)
SPEC

run "c3 a module member declares into the MODULE's tables" <<SPEC
FILE $B
<<<OLD
        if ck = KindModuleDeclaration
            return this.declare_module_member(n, symbol_flags, symbol_excludes)
>>>NEW
        if false
            return this.declare_module_member(n, symbol_flags, symbol_excludes)
SPEC

run "c4 an AMBIENT module's symbol name is QUOTED" <<SPEC
FILE $B
<<<OLD
                set *(buf + 1 + tl): "\\"" as char
                set *out_data: buf
                set *out_len: tl + 2
>>>NEW
                set *(buf + 1 + tl): "\\"" as char
                set *out_data: buf + 1
                set *out_len: tl
SPEC

run "c5 a 'global' augmentation is named by the internal 'global'" <<SPEC
FILE $B
<<<OLD
                if Binder.is_global_scope_augmentation(n)
                {
                    set *out_len: Binder.internal_name(host, "global", out_data)
                    return
                }
>>>NEW
                if false
                {
                    set *out_len: Binder.internal_name(host, "global", out_data)
                    return
                }
SPEC

run "c6 the ambient-module name is decided BEFORE the name's own kind" <<SPEC
FILE $B
<<<OLD
            if Binder.is_ambient_module(n)
            {
                if Binder.is_global_scope_augmentation(n)
>>>NEW
            if false
            {
                if Binder.is_global_scope_augmentation(n)
SPEC

run "c7 an ambient module is NOT exported by its context" <<SPEC
FILE $B
<<<OLD
        if Binder.is_ambient_module(n)
            set exported: false
>>>NEW
        if false
            set exported: false
SPEC

run "c8 an EXTERNAL augmentation takes the ordinary route" <<SPEC
FILE $B
<<<OLD
            if this.is_module_augmentation_external(n)
            {
                this.declare_module_symbol(n)
                return
            }
>>>NEW
            if false
            {
                this.declare_module_symbol(n)
                return
            }
SPEC

run "c9 an ambient module may not carry an export modifier" <<SPEC
FILE $B
<<<OLD
            if this.has_syntactic_modifier(n, ModifierFlagsExport)
                this.error_on_first_token(n, DiagX_export_modifier_cannot_be_applied_to_ambient_modules_and_module_augmentations_since_they_are_always_visible)
>>>NEW
            if false
                this.error_on_first_token(n, DiagX_export_modifier_cannot_be_applied_to_ambient_modules_and_module_augmentations_since_they_are_always_visible)
SPEC

run "c10 a module pattern may have at most ONE asterisk" <<SPEC
FILE $B
<<<OLD
            if Binder.pattern_has_at_most_one_star(AstNode.literal_text_of(name), AstNode.literal_text_length_of(name)) = false
                this.error_on_first_token(name, DiagPattern_0_can_have_at_most_one_Asterisk_character)
>>>NEW
            if false
                this.error_on_first_token(name, DiagPattern_0_can_have_at_most_one_Asterisk_character)
SPEC

run "c11 ONE asterisk is allowed — the threshold is two" <<SPEC
FILE $B
<<<OLD
        stars < 2
>>>NEW
        stars < 1
SPEC

run "c12 errorOnFirstToken reports at the first TOKEN, not at the node" <<SPEC
FILE $B
<<<OLD
        this.range_of_token_at_position(AstNode.pos_of(n), &start, &stop)
>>>NEW
        set start: AstNode.pos_of(n)
        set stop: AstNode.end_of(n)
SPEC

# ── getModuleInstanceState ───────────────────────────────────────────────────

run "c13 a module with NO body is instantiated" <<SPEC
FILE $B
<<<OLD
        let body AstNode.body_of(n)
        if body = null
            return ModuleInstanceStateInstantiated
>>>NEW
        let body AstNode.body_of(n)
        if body = null
            return ModuleInstanceStateNonInstantiated
SPEC

run "c14 an interface / type alias contributes NOTHING" <<SPEC
FILE $B
<<<OLD
        if k = KindInterfaceDeclaration
            return ModuleInstanceStateNonInstantiated
        if k = KindTypeAliasDeclaration
            return ModuleInstanceStateNonInstantiated
>>>NEW
        if false
            return ModuleInstanceStateNonInstantiated
        if false
            return ModuleInstanceStateNonInstantiated
SPEC

run "c15 the ModuleBlock walk STOPS at the first instantiated child" <<SPEC
FILE $B
<<<OLD
                    if cs = ModuleInstanceStateInstantiated
                    {
                        set state: ModuleInstanceStateInstantiated
                        set stop: true
                    }
>>>NEW
                    if cs = ModuleInstanceStateInstantiated
                        set state: ModuleInstanceStateInstantiated
SPEC

run "c16 a const enum makes a module CONST-ENUM-ONLY" <<SPEC
FILE $B
<<<OLD
            if this.has_combined_modifier(n, ModifierFlagsConst)
                return ModuleInstanceStateConstEnumOnly
>>>NEW
            if false
                return ModuleInstanceStateConstEnumOnly
SPEC

run "c17 a non-exported import contributes NOTHING" <<SPEC
FILE $B
<<<OLD
        if is_import
        {
            if this.has_syntactic_modifier(n, ModifierFlagsExport) = false
                return ModuleInstanceStateNonInstantiated
        }
>>>NEW
        if false
        {
            if this.has_syntactic_modifier(n, ModifierFlagsExport) = false
                return ModuleInstanceStateNonInstantiated
        }
SPEC

run "c18 a local export clause is resolved against the scopes above it" <<SPEC
FILE $B
<<<OLD
            if named
            {
                var state ModuleInstanceStateNonInstantiated
>>>NEW
            if false
            {
                var state ModuleInstanceStateNonInstantiated
SPEC

run "c19 an export clause WITH a module specifier is not resolved" <<SPEC
FILE $B
<<<OLD
            if AstNode.module_specifier_of(n) = null
            {
                if clause <> null
                {
                    if AstNode.kind_of(clause) = KindNamedExports
                        set named: true
                }
            }
>>>NEW
            if clause <> null
            {
                if AstNode.kind_of(clause) = KindNamedExports
                    set named: true
            }
SPEC

run "c20 an alias target must be an IDENTIFIER" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(name) <> KindIdentifier
            return ModuleInstanceStateInstantiated
>>>NEW
        if false
            return ModuleInstanceStateInstantiated
SPEC

run "c21 node_has_name recurses into a VARIABLE STATEMENT's declarations" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(st) <> KindVariableStatement
            return false
>>>NEW
        if true
            return false
SPEC

run "c22 a re-exported import ALIAS counts as instantiated" <<SPEC
FILE $B
<<<OLD
                            if AstNode.kind_of(st) = KindImportEqualsDeclaration
                                set found: ModuleInstanceStateInstantiated
>>>NEW
                            if false
                                set found: ModuleInstanceStateInstantiated
SPEC

run "c23 a CYCLE answers NonInstantiated" <<SPEC
FILE $B
<<<OLD
                if l.state <> ModuleInstanceStateUnknown
                    return l.state
                return ModuleInstanceStateNonInstantiated
>>>NEW
                if l.state <> ModuleInstanceStateUnknown
                    return l.state
                return ModuleInstanceStateInstantiated
SPEC

# ── the const-enum-only bit ──────────────────────────────────────────────────

run "c24 a const-enum-only module carries the ConstEnumOnlyModule flag" <<SPEC
FILE $B
<<<OLD
        if const_enum_only
        {
            set symbol.flags: Symbol.flags_of(symbol) | SymbolFlagsConstEnumOnlyModule
            return
        }
>>>NEW
        if false
        {
            set symbol.flags: Symbol.flags_of(symbol) | SymbolFlagsConstEnumOnlyModule
            return
        }
SPEC

run "c25 a symbol once seen NOT const-enum-only can never go back" <<SPEC
FILE $B
<<<OLD
        if this.symbol_is_not_const_enum_only(symbol)
            set const_enum_only: false
>>>NEW
        if false
            set const_enum_only: false
SPEC

run "c26 a merge with a class RESETS the const-enum-only flag" <<SPEC
FILE $B
<<<OLD
            if (s.flags & (SymbolFlagsFunction | SymbolFlagsClass | SymbolFlagsRegularEnum)) <> 0
            {
                Binder.clear_const_enum_only_module(s)
                this.add_not_const_enum_only(s)
            }
>>>NEW
            if false
            {
                Binder.clear_const_enum_only_module(s)
                this.add_not_const_enum_only(s)
            }
SPEC

run "c27 a non-namespace declaration takes over the VALUE declaration" <<SPEC
FILE $B
<<<OLD
        if Binder.is_effective_module_declaration(s.value_declaration)
            set s.value_declaration: n
>>>NEW
        if false
            set s.value_declaration: n
SPEC

run "c28 an existing prototype export is a duplicate identifier" <<SPEC
FILE $B
<<<OLD
                this.error_on_node(Symbol.declaration_at(existing, 0), DiagDuplicate_identifier_0)
>>>NEW
                this.record_unported("prototype-duplicate", 0)
SPEC

# ── the enum ─────────────────────────────────────────────────────────────────

run "c29 a const enum is a ConstEnum, a plain one a RegularEnum" <<SPEC
FILE $B
<<<OLD
        if this.has_combined_modifier(n, ModifierFlagsConst)
            this.bind_block_scoped_declaration(n, SymbolFlagsConstEnum, SymbolFlagsConstEnumExcludes)
>>>NEW
        if false
            this.bind_block_scoped_declaration(n, SymbolFlagsConstEnum, SymbolFlagsConstEnumExcludes)
SPEC

run "c30 an enum member declares into the enum's EXPORTS" <<SPEC
FILE $B
<<<OLD
        if ck = KindEnumDeclaration
        {
            let es AstNode.symbol_of(container)
            return this.declare_symbol(Symbol.get_exports(host, es), es, n, symbol_flags, symbol_excludes)
        }
>>>NEW
        if false
        {
            let es AstNode.symbol_of(container)
            return this.declare_symbol(Symbol.get_exports(host, es), es, n, symbol_flags, symbol_excludes)
        }
SPEC

# ── the literal text ─────────────────────────────────────────────────────────

run "c36 an ambient module with an export declaration is NOT an export context" <<SPEC
FILE $B
<<<OLD
        if k = KindModuleDeclaration
        {
            let body AstNode.body_of(n)
            if body <> null
            {
                if AstNode.kind_of(body) = KindModuleBlock
                    set statements: AstNode.statements_of(body)
            }
        }
>>>NEW
        if false
        {
            let body AstNode.body_of(n)
            if body <> null
            {
                if AstNode.kind_of(body) = KindModuleBlock
                    set statements: AstNode.statements_of(body)
            }
        }
SPEC

run "c31 a STRING-named declaration is named by its text" <<SPEC
FILE $B
<<<OLD
            if nk = KindStringLiteral
            {
                this.literal_declaration_name(name, out_data, out_len)
                return
            }
>>>NEW
            if nk = KindStringLiteral
            {
                set *out_len: Binder.internal_name(host, "missing", out_data)
                return
            }
SPEC

run "c32 a LITERAL computed name is the literal's text" <<SPEC
FILE $B
<<<OLD
                if Binder.is_string_or_numeric_literal_like(ne)
                {
                    this.literal_declaration_name(ne, out_data, out_len)
                    return
                }
>>>NEW
                if Binder.is_string_or_numeric_literal_like(ne)
                {
                    set *out_len: Binder.internal_name(host, "missing", out_data)
                    return
                }
SPEC

run "c33 a SIGNED numeric computed name keeps its sign" <<SPEC
FILE $B
<<<OLD
                    if sign = KindMinusToken
                        set *buf: "-" as char
                    else
                        set *buf: "+" as char
>>>NEW
                    if sign = KindMinusToken
                        set *buf: "+" as char
                    else
                        set *buf: "+" as char
SPEC

run "c34 a literal carries the TOKEN's value, not the next one's" <<SPEC
FILE $P
<<<OLD
        let text scanner.token_value()
        let text_len scanner.token_value_length()

        this.next_token()
>>>NEW
        this.next_token()
        let text scanner.token_value()
        let text_len scanner.token_value_length()
SPEC

run "c37 a numeric literal's SOURCE text is only sometimes its name" <<SPEC
FILE $B
<<<OLD
            if Binder.numeric_text_is_canonical(AstNode.literal_text_of(name), AstNode.literal_text_length_of(name)) = false
>>>NEW
            if false
SPEC

run "c35 set_entry REPLACES an existing entry" <<SPEC
FILE $A
<<<OLD
                        let slot_ptr t.entries.get_buffer() + (idx - 1)
                        set slot_ptr.symbol: sym
                        return
>>>NEW
                        return
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl31-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl31-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl31-final.log | head -30
  exit 1
fi
