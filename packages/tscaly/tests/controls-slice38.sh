#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice38.sh — the slice-38 control battery, thirty-six of them.
#
# Slice 38 is the DEFERRED EXPANDO PASS: the two remaining assignment-declaration
# kinds that do not go through setCommonJSModuleIndicator — `f.a = 1`
# (JSDeclarationKindProperty) and `Object.defineProperty(f, "a", …)`
# (ObjectDefinePropertyValue) — bound after the whole walk, out of a list of nodes
# each carrying the container registers of its own moment.
#
# ★★★ SIX GROUPS, BECAUSE THE SLICE MAKES SIX DIFFERENT KINDS OF CLAIM.
#
#   c1..c3    what the slice UNLOCKS: the two arms, and the pass itself.
#
#   c4..c7    THE CONDITION OF THE PASS, which is what §3.5l says has to be
#             ported exactly rather than approximated. That a second pass exists
#             is not the claim — WHEN it runs and WHICH scope each entry is
#             resolved in is. c4 binds immediately, c5 drops the per-entry
#             registers, c6 swaps the order of the two lookups, c7 removes the
#             second one.
#
#   c8..c19   getInitializerSymbol and IsExpandoInitializer, arm by arm: the gate
#             that decides whether a NAME can carry expando declarations at all.
#             Six of these rows are about a JavaScript-only arm, in both
#             directions — remove the arm, and remove its IsInJSFile test.
#
#   c20..c23  the declaration itself: the reference's "only when there are no
#             non-expando declarations for that name" test, the two flags and the
#             table.
#
#   c24..c30  the LATE-BOUND half — a dynamically named expando (`f[k] = 1`) gets
#             an anonymous `computed` symbol plus a collection on ONE internal
#             `assignment` symbol — and the IsDynamicName arm this slice had to
#             port to reach it, whose old marker carried a claim that had already
#             expired (§3.5p).
#
#   c31..c36  the LOOKUP: lookupName's two halves and its ExportSymbol hop,
#             lookupEntity's recursion through getInitializerSymbol, and the two
#             rows that record the `this` branch's verdict rather than gate it.
#
# ★★★ THREE ROWS ARE EXPECTED TO COME BACK UNGATED WITH AN ARGUMENT, NOT WITH A
# SHRUG (§3.5v), and two of them are one finding seen twice: the deferred pass
# restores TWO of the three container registers, and `this_container` is null by
# the time it runs — bindContainer put it back when the walk of the SourceFile
# returned. So lookupEntity's `this` branch and everything under
# getThisClassAndSymbolTable answer null for every `this.a.b = x` in the corpus,
# and the code is written the reference's way anyway. The third is
# skip_parentheses inside the IsDynamicName arm, which is redundant for its only
# caller and provably so.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice38.sh 2>&1 | tee /tmp/battery38.log
#
# 1 baseline + 36 controls + 1 verifying run = 38 runs, about 9 minutes.

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

run "c1 f.a = 1 is bound (the Property kind)" <<SPEC
FILE $B
<<<OLD
            if adk = JSDeclarationKindProperty
                this.bind_expando_property_assignment(n)
>>>NEW
            if adk = JSDeclarationKindProperty
                this.record_unported("assignment-declaration", adk)
SPEC

run "c2 Object.defineProperty(f, ...) is bound (the ObjectDefinePropertyValue kind)" <<SPEC
FILE $B
<<<OLD
            if adk = JSDeclarationKindObjectDefinePropertyValue
                this.bind_expando_property_assignment(n)
>>>NEW
            if adk = JSDeclarationKindObjectDefinePropertyValue
                this.record_unported("assignment-declaration", adk)
SPEC

run "c3 the deferred pass runs at all" <<SPEC
FILE $B
<<<OLD
        if b.is_unported() = false
            b.bind_deferred_expando_assignments()
>>>NEW
SPEC

# ── group 2: the CONDITION of the pass (§3.5l) ───────────────────────────────
#
# ★★★ The rule §3.5l states is that a second pass is its own slice BUT its
# condition has to be ported exactly, and c4 is that rule's whole content here: a
# port that bound the expando where it met it would agree on every file whose
# assignment comes AFTER the declaration it extends — which is most of them — and
# be silently wrong on the rest. Function declarations hoist, so "the rest" is
# ordinary code and not a corner.

run "c4 the pass is DEFERRED rather than bound where it is met" <<SPEC
FILE $B
<<<OLD
        expando_assignments.add(ExpandoAssignmentInfo(n, container, block_scope_container))
>>>NEW
        this.bind_deferred_expando_assignment(n)
SPEC

run "c5 each entry carries its OWN container registers" <<SPEC
FILE $B
<<<OLD
            set container: info.container
            set block_scope_container: info.block_scope_container
>>>NEW
SPEC

run "c6 the BLOCK-SCOPE container is asked first" <<SPEC
FILE $B
<<<OLD
        var symbol this.lookup_entity(parent, block_scope_container)
        if this.is_unported()
            return
        if symbol = null
        {
            set symbol: this.lookup_entity(parent, container)
>>>NEW
        var symbol this.lookup_entity(parent, container)
        if this.is_unported()
            return
        if symbol = null
        {
            set symbol: this.lookup_entity(parent, block_scope_container)
SPEC

run "c7 the CONTAINER is asked when the block scope answered nothing" <<SPEC
FILE $B
<<<OLD
        if symbol = null
        {
            set symbol: this.lookup_entity(parent, container)
            if this.is_unported()
                return
        }
>>>NEW
        if symbol = null
            return
SPEC

# ── group 3: getInitializerSymbol and IsExpandoInitializer ───────────────────

run "c8 a FUNCTION DECLARATION is expando-extensible" <<SPEC
FILE $B
<<<OLD
        if k = KindFunctionDeclaration
            return s
        if k = KindClassDeclaration
>>>NEW
        if k = KindClassDeclaration
SPEC

run "c9 a JavaScript CLASS DECLARATION is too" <<SPEC
FILE $B
<<<OLD
        if k = KindClassDeclaration
        {
            if Parser.is_in_js_file(d)
                return s
            return null
        }
>>>NEW
SPEC

run "c10 ... and only in a JavaScript file" <<SPEC
FILE $B
<<<OLD
        if k = KindClassDeclaration
        {
            if Parser.is_in_js_file(d)
                return s
            return null
        }
>>>NEW
        if k = KindClassDeclaration
            return s
SPEC

run "c11 a VARIABLE must be const, or in a JavaScript file" <<SPEC
FILE $B
<<<OLD
            if extensible = false
                return null
>>>NEW
SPEC

run "c12 a variable's host is its INITIALIZER's symbol, not its own" <<SPEC
FILE $B
<<<OLD
            let iv AstNode.initializer_of(d)
            if Binder.is_expando_initializer(d, iv)
                return AstNode.symbol_of(iv)
>>>NEW
            let iv AstNode.initializer_of(d)
            if Binder.is_expando_initializer(d, iv)
                return s
SPEC

run "c13 a value declaration that is itself an ASSIGNMENT can host expandos" <<SPEC
FILE $B
<<<OLD
        if k = KindBinaryExpression
        {
            if Parser.is_in_js_file(d) = false
                return null
            let rhs AstNode.binary_right_of(d)
            if Binder.is_expando_initializer(d, rhs)
                return AstNode.symbol_of(rhs)
            return null
        }
>>>NEW
SPEC

run "c14 a FUNCTION EXPRESSION is an expando initializer" <<SPEC
FILE $B
<<<OLD
        if k = KindFunctionExpression
            return true
        if k = KindArrowFunction
            return true
        if Parser.is_in_js_file(initializer) = false
>>>NEW
        if k = KindArrowFunction
            return true
        if Parser.is_in_js_file(initializer) = false
SPEC

run "c15 an ARROW is one" <<SPEC
FILE $B
<<<OLD
        if k = KindArrowFunction
            return true
        if Parser.is_in_js_file(initializer) = false
>>>NEW
        if Parser.is_in_js_file(initializer) = false
SPEC

run "c16 a CLASS EXPRESSION is one, in a JavaScript file" <<SPEC
FILE $B
<<<OLD
        if k = KindClassExpression
            return true
        if k <> KindObjectLiteralExpression
>>>NEW
        if k <> KindObjectLiteralExpression
SPEC

run "c17 an EMPTY OBJECT LITERAL is one, in a JavaScript file" <<SPEC
FILE $B
<<<OLD
        if k <> KindObjectLiteralExpression
            return false
        let props AstNode.properties_of(initializer)
        if props <> null
        {
            if props.get_length() <> 0
                return false
        }
        AstNode.type_of(declaration) = null
>>>NEW
        false
SPEC

run "c18 ... and only while it has NO properties" <<SPEC
FILE $B
<<<OLD
            if props.get_length() <> 0
                return false
>>>NEW
SPEC

run "c19 ... and only while the declaration has NO type annotation" <<SPEC
FILE $B
<<<OLD
        AstNode.type_of(declaration) = null
    }
>>>NEW
        true
    }
SPEC

run "c20 the last two arms are JAVASCRIPT-only" <<SPEC
FILE $B
<<<OLD
        if Parser.is_in_js_file(initializer) = false
            return false
        if k = KindClassExpression
>>>NEW
        if k = KindClassExpression
SPEC

# ── group 4: the declaration ─────────────────────────────────────────────────

run "c21 an expando is dropped where a NON-expando of that name exists" <<SPEC
FILE $B
<<<OLD
        if existing <> null
        {
            if (Symbol.flags_of(existing) & SymbolFlagsAssignment) = 0
                set declares: false
        }
>>>NEW
SPEC

run "c22 the symbol carries the ASSIGNMENT flag" <<SPEC
FILE $B
<<<OLD
            this.declare_symbol(exports, symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, SymbolFlagsPropertyExcludes)
>>>NEW
            this.declare_symbol(exports, symbol, n, SymbolFlagsProperty, SymbolFlagsPropertyExcludes)
SPEC

run "c23 its excludes are PropertyExcludes" <<SPEC
FILE $B
<<<OLD
            this.declare_symbol(exports, symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, SymbolFlagsPropertyExcludes)
>>>NEW
            this.declare_symbol(exports, symbol, n, SymbolFlagsProperty | SymbolFlagsAssignment, 0)
SPEC

run "c24 it declares into the host's EXPORTS, not its members" <<SPEC
FILE $B
<<<OLD
        let exports Symbol.get_exports(host, symbol)
        var dd null as pointer[char]
>>>NEW
        let exports Symbol.get_members(host, symbol)
        var dd null as pointer[char]
SPEC

# ── group 5: the late-bound half ─────────────────────────────────────────────

run "c25 a DYNAMIC name takes the late-bound route" <<SPEC
FILE $B
<<<OLD
        if this.has_dynamic_name(n)
        {
            var nd null as pointer[char]
>>>NEW
        if false
        {
            var nd null as pointer[char]
SPEC

run "c26 a dynamic expando gets an ANONYMOUS computed symbol" <<SPEC
FILE $B
<<<OLD
            this.bind_anonymous_declaration(n, SymbolFlagsProperty | SymbolFlagsAssignment, nd, nl)
            this.add_late_bound_assignment_declaration_to_symbol(n, symbol)
>>>NEW
            this.add_late_bound_assignment_declaration_to_symbol(n, symbol)
SPEC

run "c27 ... and is collected on the host's internal assignment symbol" <<SPEC
FILE $B
<<<OLD
            this.add_late_bound_assignment_declaration_to_symbol(n, symbol)
>>>NEW
SPEC

run "c28 that assignment symbol is made ONCE for the host" <<SPEC
FILE $B
<<<OLD
        var a SymbolTable.get(exports, nd, nl)
        if a = null
        {
>>>NEW
        var a null as pointer[Symbol]
        if a = null
        {
SPEC

run "c29 the late-bound append does not write the node's own symbol" <<SPEC
FILE $B
<<<OLD
        if a.declarations = null
        {
            let list host.allocate(sizeof Array[pointer[AstNode]], alignof Array[pointer[AstNode]]) as pointer[Array[pointer[AstNode]]]
            set *list: Array[pointer[AstNode]]()
            set a.declarations: list
        }
        a.declarations.add(n)
>>>NEW
        this.add_declaration_to_symbol(a, n, SymbolFlagsNone)
SPEC

run "c30 an ELEMENT ACCESS can be a dynamic name (the marker this slice retired)" <<SPEC
FILE $B
<<<OLD
            let arg Parser.skip_parentheses(AstNode.element_access_argument_of(name))
            if Binder.is_string_or_numeric_literal_like(arg)
                return false
            if AstNode.is_signed_numeric_literal(arg)
                return false
            return true
>>>NEW
            this.record_unported("dynamic-name-element-access", 0)
            return false
SPEC

run "c31 that arm skips PARENTHESES around the subscript" <<SPEC
FILE $B
<<<OLD
            let arg Parser.skip_parentheses(AstNode.element_access_argument_of(name))
>>>NEW
            let arg AstNode.element_access_argument_of(name)
SPEC

# ── group 6: the lookup ──────────────────────────────────────────────────────

run "c32 lookupName reads the container's LOCALS" <<SPEC
FILE $B
<<<OLD
        let locals AstNode.locals_of(container_node)
        if locals <> null
>>>NEW
        let locals null as pointer[SymbolTable]
        if locals <> null
SPEC

run "c33 ... and answers a local's EXPORT symbol where it has one" <<SPEC
FILE $B
<<<OLD
                let ex Symbol.export_symbol_of(local)
                if ex <> null
                    return ex
                return local
>>>NEW
                return local
SPEC

run "c34 ... and falls back to the container SYMBOL's exports" <<SPEC
FILE $B
<<<OLD
        let cs AstNode.symbol_of(container_node)
        if cs = null
            return null
        SymbolTable.get(Symbol.exports_of(cs), name_data, name_len)
>>>NEW
        null
SPEC

run "c35 a dotted hop goes through getInitializerSymbol" <<SPEC
FILE $B
<<<OLD
        let base Binder.get_initializer_symbol(this.lookup_entity(inner, container_node))
>>>NEW
        let base this.lookup_entity(inner, container_node)
SPEC

run "c36 a THIS-rooted hop asks getThisClassAndSymbolTable" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(inner) = KindThisKeyword
        {
            var cs null as pointer[Symbol]
            let tbl this.get_this_class_and_symbol_table(&cs)
            if tbl = null
                return null
            let tnm Parser.get_element_or_property_access_name(n)
            if tnm = null
                return null
            var tnd null as pointer[char]
            var tnl 0
            this.entity_access_name_text(tnm, &tnd, &tnl)
            if this.is_unported()
                return null
            return SymbolTable.get(tbl, tnd, tnl)
        }

>>>NEW
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl38-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl38-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl38-final.log | head -30
  exit 1
fi
