#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice30.sh — the slice-30 control battery, twenty-nine of them.
#
# Slice 30 is the CLASS-LIKE family and its MEMBERS: a class declaration and a
# class expression, an interface, a type alias (both spellings), the two
# anonymous type containers — and the ten member kinds that declare into the
# tables those containers own. The claims are almost all of the same two shapes,
# WHICH TABLE a symbol lands in and WHAT FLAGS it carries, and the symbols dump
# compares both exactly, so a battery here is cheap and sharp.
#
# ★★★ THE ROWS TO READ FIRST ARE c1 AND c9, TOGETHER. They are the argument for
# why the containers and the members are ONE slice: c1 breaks the class's own
# declaration and c9 breaks the table its members declare into, and neither is
# reachable without the other. Shipping the containers alone would have parked
# declareClassMember and the members arm as unreachable — the exact debt slice 29
# had to pay off for slice 28's c13.
#
# ★★ THREE ROWS ARE EXPECTED UNGATED and each names which of §3.5v's four reasons
# it is, all three *unreachable* — and one of them, c24, only became so by being
# measured; its header paragraph is the finding. c19 is the static-BLOCK arm of is_static: a
# ClassStaticBlockDeclaration has no bind arm in the reference at all, so it never
# asks declareClassMember and the arm can only matter to a later slice. c20 is an
# object-literal method's excludes: an ObjectLiteralExpression's bind arm is still
# unported, so a method of one never reaches bind_method — the slice that binds an
# object literal owns that row.
#
# ★ A THIRD claim of this slice has no control at all, deliberately: the
# `declareCommonJSVariable("module")` / `("exports")` pair of the bindContainer
# tail is not ported, because every writer of CommonJSModuleIndicator is an
# unported JS expando arm. There is nothing to break, and a control that patches
# absent code would report UNGATED for the wrong reason.
#
# ★ c11 and c29 break their claim by making a test always TRUE rather than by
# disabling a branch, which ctl.sh's header warns reports too HIGH. It is
# deliberate in both: c10 already measures the "nothing is static" direction, so
# c11 measures the other one, and c29 asks how many exports are NOT types.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice30.sh 2>&1 | tee /tmp/battery30.log
#
# 1 baseline + 29 controls + 1 verifying run = 31 runs.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
B=packages/tscaly/0.1.0/tscaly/binder.scaly
A=packages/tscaly/0.1.0/tscaly/ast.scaly

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

# ── the containers ───────────────────────────────────────────────────────────

run "c1 a ClassDeclaration declares a block-scoped CLASS symbol" <<SPEC
FILE $B
<<<OLD
        if k = KindClassDeclaration
            this.bind_class_like_declaration(n)
>>>NEW
        if false
            this.bind_class_like_declaration(n)
SPEC

run "c2 a class's flags are Class, and its excludes are ClassExcludes" <<SPEC
FILE $B
<<<OLD
        if k = KindClassDeclaration
            this.bind_block_scoped_declaration(n, SymbolFlagsClass, SymbolFlagsClassExcludes)
>>>NEW
        if k = KindClassDeclaration
            this.bind_block_scoped_declaration(n, SymbolFlagsInterface, SymbolFlagsClassExcludes)
SPEC

run "c3 a class EXPRESSION is anonymous, not block-scoped" <<SPEC
FILE $B
<<<OLD
            this.bind_anonymous_declaration(n, SymbolFlagsClass, nd, nl)
>>>NEW
            this.bind_block_scoped_declaration(n, SymbolFlagsClass, SymbolFlagsClassExcludes)
SPEC

run "c4 an UNNAMED class expression takes the internal 'class' name" <<SPEC
FILE $B
<<<OLD
            if name = null
                set nl: Binder.internal_name(host, "class", &nd)
>>>NEW
            if name = null
                set nl: Binder.internal_name(host, "missing", &nd)
SPEC

run "c5 a NAMED class expression adds its name to classifiableNames" <<SPEC
FILE $B
<<<OLD
                SymbolTable.set_entry(host, classifiable_names, nd, nl, null as pointer[Symbol])
            }
            this.bind_anonymous_declaration(n, SymbolFlagsClass, nd, nl)
>>>NEW
            }
            this.bind_anonymous_declaration(n, SymbolFlagsClass, nd, nl)
SPEC

run "c6 an interface is a block-scoped INTERFACE" <<SPEC
FILE $B
<<<OLD
        if k = KindInterfaceDeclaration
            this.bind_block_scoped_declaration(n, SymbolFlagsInterface, SymbolFlagsInterfaceExcludes)
>>>NEW
        if false
            this.bind_block_scoped_declaration(n, SymbolFlagsInterface, SymbolFlagsInterfaceExcludes)
SPEC

run "c7 a type alias is a block-scoped TYPE ALIAS" <<SPEC
FILE $B
<<<OLD
        if k = KindTypeAliasDeclaration
            this.bind_block_scoped_declaration(n, SymbolFlagsTypeAlias, SymbolFlagsTypeAliasExcludes)
>>>NEW
        if false
            this.bind_block_scoped_declaration(n, SymbolFlagsTypeAlias, SymbolFlagsTypeAliasExcludes)
SPEC

run "c8 a type literal / mapped type gets an anonymous 'type' symbol" <<SPEC
FILE $B
<<<OLD
        var nd null as pointer[char]
        let nl Binder.internal_name(host, "type", &nd)
        this.bind_anonymous_declaration(n, SymbolFlagsTypeLiteral, nd, nl)
>>>NEW
        var nd null as pointer[char]
        let nl Binder.internal_name(host, "type", &nd)
        if false
            this.bind_anonymous_declaration(n, SymbolFlagsTypeLiteral, nd, nl)
SPEC

# ── the tables the members declare into ──────────────────────────────────────

run "c9 a class member declares into the CLASS's tables" <<SPEC
FILE $B
<<<OLD
        if ck = KindClassDeclaration
            return this.declare_class_member(n, symbol_flags, symbol_excludes)
>>>NEW
        if false
            return this.declare_class_member(n, symbol_flags, symbol_excludes)
SPEC

run "c10 a STATIC member is an EXPORT, an instance member a MEMBER" <<SPEC
FILE $B
<<<OLD
        if this.is_static(n)
            return this.declare_symbol(Symbol.get_exports(host, cs), cs, n, symbol_flags, symbol_excludes)
>>>NEW
        if false
            return this.declare_symbol(Symbol.get_exports(host, cs), cs, n, symbol_flags, symbol_excludes)
SPEC

run "c11 is_static reads the STATIC modifier" <<SPEC
FILE $B
<<<OLD
        if Binder.is_class_element(n) = false
            return false
        this.has_syntactic_modifier(n, ModifierFlagsStatic)
>>>NEW
        if Binder.is_class_element(n) = false
            return false
        true
SPEC

run "c12 a class member's PARENT is the class symbol" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(Symbol.get_members(host, cs), cs, n, symbol_flags, symbol_excludes)
    }
>>>NEW
        this.declare_symbol(Symbol.get_members(host, cs), null as pointer[Symbol], n, symbol_flags, symbol_excludes)
    }
SPEC

run "c13 an interface / type-literal member declares into MEMBERS" <<SPEC
FILE $B
<<<OLD
        if Binder.container_declares_into_members(ck)
        {
            let ms AstNode.symbol_of(container)
>>>NEW
        if false
        {
            let ms AstNode.symbol_of(container)
SPEC

# ── the members themselves ───────────────────────────────────────────────────

run "c14 a property declaration declares a PROPERTY" <<SPEC
FILE $B
<<<OLD
        if k = KindPropertyDeclaration
            this.bind_property_worker(n)
>>>NEW
        if false
            this.bind_property_worker(n)
SPEC

run "c15 an AUTO-ACCESSOR property is an Accessor, not a Property" <<SPEC
FILE $B
<<<OLD
        if this.is_auto_accessor_property_declaration(n)
        {
            set includes: SymbolFlagsAccessor
>>>NEW
        if false
        {
            set includes: SymbolFlagsAccessor
SPEC

run "c16 a POSTFIX question mark makes the member Optional — and a '!' does not" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(pt) = KindQuestionToken
            return SymbolFlagsOptional
        SymbolFlagsNone
>>>NEW
        SymbolFlagsOptional
SPEC

run "c17 a method declares a METHOD, and the signatures a SIGNATURE" <<SPEC
FILE $B
<<<OLD
        if k = KindCallSignature
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsSignature, SymbolFlagsNone)
>>>NEW
        if k = KindCallSignature
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsMethod, SymbolFlagsNone)
SPEC

run "c18 a constructor takes the internal 'constructor' name and Constructor flag" <<SPEC
FILE $B
<<<OLD
        if k = KindConstructor
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsConstructor, SymbolFlagsNone)
>>>NEW
        if false
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsConstructor, SymbolFlagsNone)
SPEC

run "c19 (expected UNGATED-unreachable) is_static's static-BLOCK arm" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(n) = KindClassStaticBlockDeclaration
            return true
        if Binder.is_class_element(n) = false
>>>NEW
        if Binder.is_class_element(n) = false
SPEC

run "c20 (expected UNGATED-unreachable) an object-literal method excludes every VALUE" <<SPEC
FILE $B
<<<OLD
        if Binder.is_object_literal_method(n)
            set excludes: SymbolFlagsValue
>>>NEW
        if false
            set excludes: SymbolFlagsValue
SPEC

# ── the dynamic-name question ────────────────────────────────────────────────

run "c21 a DYNAMIC computed name gets an anonymous 'computed' symbol" <<SPEC
FILE $B
<<<OLD
        if dynamic
        {
            var nd null as pointer[char]
>>>NEW
        if false
        {
            var nd null as pointer[char]
SPEC

run "c22 a computed name whose expression is a LITERAL is NOT dynamic" <<SPEC
FILE $B
<<<OLD
        if Binder.is_string_or_numeric_literal_like(expr)
            return false
        if AstNode.is_signed_numeric_literal(expr)
            return false
        true
>>>NEW
        true
SPEC

# ── the prototype symbol and the tail ────────────────────────────────────────

run "c23 every class carries a synthesized static 'prototype'" <<SPEC
FILE $B
<<<OLD
        SymbolTable.set_entry(host, exports, pd, pl, ps)
        set ps.parent: symbol
>>>NEW
        set ps.parent: symbol
SPEC

# ★★★ c24 is the row that changed its own claim. The fixture written for it —
# `class A { static prototype: number }` — does NOT produce the diagnostic, and
# finding out why is the finding: the class is bound BEFORE its members, and
# Property is not in PropertyExcludes, so a `static prototype` MERGES into the
# synthesized symbol instead of colliding with it. What TypeScript reports about
# that member is TS2699, from the checker. The binder's TS2300 needs a class
# merging into a NAMESPACE that exports a `prototype` — the case the reference's
# own comment names — and the module bind arm is unported.
run "c24 (expected UNGATED-unreachable) an existing prototype export is a duplicate" <<SPEC
FILE $B
<<<OLD
            if Symbol.declaration_count(existing) = 0
                this.record_unported("prototype-export-without-declaration", 0)
            else
                this.error_on_node(Symbol.declaration_at(existing, 0), DiagDuplicate_identifier_0)
>>>NEW
            if false
                this.record_unported("prototype-export-without-declaration", 0)
SPEC

run "c25 the prototype name is UNPREFIXED" <<SPEC
FILE $B
<<<OLD
        let pl Binder.internal_name_unprefixed(host, "prototype", &pd)
>>>NEW
        let pl Binder.internal_name(host, "prototype", &pd)
SPEC

run "c26 a TOP-LEVEL JS typedef is bound by the bindContainer TAIL" <<SPEC
FILE $B
<<<OLD
                            if AstNode.kind_of(st) = KindJSTypeAliasDeclaration
                                this.bind_block_scoped_declaration(st, SymbolFlagsTypeAlias, SymbolFlagsTypeAliasExcludes)
>>>NEW
                            if false
                                this.bind_block_scoped_declaration(st, SymbolFlagsTypeAlias, SymbolFlagsTypeAliasExcludes)
SPEC

run "c27 a NON-top-level JS typedef is bound by the bind ARM" <<SPEC
FILE $B
<<<OLD
            if AstNode.kind_of(block_scope_container) <> KindSourceFile
                this.bind_block_scoped_declaration(n, SymbolFlagsTypeAlias, SymbolFlagsTypeAliasExcludes)
>>>NEW
            if false
                this.bind_block_scoped_declaration(n, SymbolFlagsTypeAlias, SymbolFlagsTypeAliasExcludes)
SPEC

run "c28 an external module's TYPE exports are folded into its 'export=' symbol" <<SPEC
FILE $B
<<<OLD
            if this.is_unported() = false
                this.bind_common_js_type_exports(AstNode.symbol_of(n))
>>>NEW
            if false
                this.bind_common_js_type_exports(AstNode.symbol_of(n))
SPEC

run "c29 only a TYPE or NAMESPACE export is folded in" <<SPEC
FILE $B
<<<OLD
                    if (Symbol.flags_of(sym) & (SymbolFlagsType | SymbolFlagsNamespace)) <> 0
>>>NEW
                    if true
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl30-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl30-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl30-final.log | head -30
  exit 1
fi
