#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice37.sh — the slice-37 control battery, thirty-four of them.
#
# Slice 37 opens the JavaScript assignment-declaration family from the end that
# has ONE piece of machinery behind it: setCommonJSModuleIndicator. Three of the
# five kinds go through it — `module.exports = x` (ModuleExports), `exports.a = x`
# / `module.exports.a = x` (ExportsProperty) and
# `Object.defineProperty(exports, …)` (ObjectDefinePropertyExports) — together
# with bindCallExpression, whose whole content is that a bare `require(...)` makes
# a file a CommonJS module. The other two kinds need the DEFERRED expando pass and
# keep reporting.
#
# ★★★ THE BATTERY IS IN FIVE GROUPS BECAUSE THE SLICE HAS FIVE DIFFERENT CLAIMS.
#
#   c1..c5    what each ported entry UNLOCKS. Each row puts the pre-slice
#             `record_unported` back at that one site, so the number is the units
#             that entry was parking. ★c5 is not a switch arm at all: it is the
#             stand-in `is_variable_declaration_initialized_to_require`, which
#             answered `false` unconditionally and could not be seen while every
#             unit carrying one was parked at c4's marker.
#
#   c6..c17   THE FIELD SPLIT. `is_external_module` used to answer both
#             `IsExternalModule` and `IsExternalOrCommonJSModule`, because until
#             this slice nothing could write the second indicator. Ten sites read
#             one or the other, and each row makes ONE of them read the wrong one.
#             Both directions are here: c6..c11 widen a site that must stay
#             EXTERNAL, c12..c17 narrow one that must be the disjunction.
#             ★ The widening direction is the dangerous one and it is why the
#             group exists: at three of those sites the only consequence is which
#             of three strict-mode MESSAGES is reported, i.e. a well-formed wrong
#             answer that no crash and no shape check can see.
#
#   c18..c26  the three arms' own content — the alias/property choice, the two
#             excludes, the value declaration, the indicator's guard and its
#             first-wins rule, and the `require` call's two tests.
#
#   c27..c29  GetNonAssignedNameOfDeclaration's JS arms, which are what names the
#             symbol these arms declare.
#
#   c30..c34  IsVariableDeclarationInitializedToRequire, one row per conjunct,
#             plus the SetValueDeclaration disjunct this slice made reachable.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice37.sh 2>&1 | tee /tmp/battery37.log
#
# 1 baseline + 34 controls + 1 verifying run = 36 runs, about 8 minutes.

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

# ── group 1: what each ported entry unlocks ──────────────────────────────────

run "c1 module.exports = x is bound" <<SPEC
FILE $B
<<<OLD
            if adk = JSDeclarationKindModuleExports
                this.bind_module_exports_assignment(n)
>>>NEW
            if adk = JSDeclarationKindModuleExports
                this.record_unported("assignment-declaration", adk)
SPEC

run "c2 exports.a = x is bound" <<SPEC
FILE $B
<<<OLD
            if adk = JSDeclarationKindExportsProperty
                this.bind_exports_or_object_define_property(n)
>>>NEW
            if adk = JSDeclarationKindExportsProperty
                this.record_unported("assignment-declaration", adk)
SPEC

run "c3 Object.defineProperty(exports, ...) is bound" <<SPEC
FILE $B
<<<OLD
            if adk = JSDeclarationKindObjectDefinePropertyExports
                this.bind_exports_or_object_define_property(n)
>>>NEW
            if adk = JSDeclarationKindObjectDefinePropertyExports
                this.record_unported("assignment-declaration", adk)
SPEC

run "c4 a require call makes the file a CommonJS module" <<SPEC
FILE $B
<<<OLD
            if Parser.is_in_js_file(n)
                this.bind_call_expression(n)
>>>NEW
            if Parser.is_in_js_file(n)
            {
                if Parser.is_require_call(n, false)
                    this.record_unported("commonjs-require", 0)
            }
SPEC

run "c5 const a = require(m) is an ALIAS (the stand-in this slice retired)" <<SPEC
FILE $B
<<<OLD
        if this.is_variable_declaration_initialized_to_require(n)
        {
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
            return
        }
>>>NEW
        if this.is_variable_declaration_initialized_to_require(n)
        {
            this.record_unported("variable-initialized-to-require", 0)
            return
        }
SPEC

# ── group 2: the field split, in both directions ─────────────────────────────
#
# ★★★ These rows are the reason the split had to be made at all, and reading them
# as one group is the point: a single field answering two questions is not a
# simplification, it is six wrong answers waiting for the first writer of the
# second indicator.

run "c6 declare_source_file_member asks IsExternalModule, not the disjunction" <<SPEC
FILE $B
<<<OLD
    procedure declare_source_file_member(this, n: pointer[AstNode], symbol_flags: int, symbol_excludes: int) returns pointer[Symbol]
    {
        if is_external_module
>>>NEW
    procedure declare_source_file_member(this, n: pointer[AstNode], symbol_flags: int, symbol_excludes: int) returns pointer[Symbol]
    {
        if this.is_external_or_common_js_module()
SPEC

run "c7 bind_namespace_export_declaration asks IsExternalModule" <<SPEC
FILE $B
<<<OLD
        if is_external_module = false
        {
            this.error_on_node(n, DiagGlobal_module_exports_may_only_appear_in_module_files)
>>>NEW
        if this.is_external_or_common_js_module() = false
        {
            this.error_on_node(n, DiagGlobal_module_exports_may_only_appear_in_module_files)
SPEC

run "c8 the top-level await check asks IsExternalModule" <<SPEC
FILE $B
<<<OLD
        if original = KindAwaitKeyword
        {
            if is_external_module
>>>NEW
        if original = KindAwaitKeyword
        {
            if this.is_external_or_common_js_module()
SPEC

run "c9 the strict-mode IDENTIFIER message asks the external indicator" <<SPEC
FILE $B
<<<OLD
        if is_external_module
            return DiagIdentifier_expected_0_is_a_reserved_word_in_strict_mode_Modules_are_automatically_in_strict_mode
>>>NEW
        if this.is_external_or_common_js_module()
            return DiagIdentifier_expected_0_is_a_reserved_word_in_strict_mode_Modules_are_automatically_in_strict_mode
SPEC

run "c10 the strict-mode EVAL/ARGUMENTS message asks the external indicator" <<SPEC
FILE $B
<<<OLD
        if is_external_module
            return DiagInvalid_use_of_0_Modules_are_automatically_in_strict_mode
>>>NEW
        if this.is_external_or_common_js_module()
            return DiagInvalid_use_of_0_Modules_are_automatically_in_strict_mode
SPEC

run "c11 is_module_augmentation_external asks the external indicator" <<SPEC
FILE $B
<<<OLD
        if pk = KindSourceFile
            return is_external_module
>>>NEW
        if pk = KindSourceFile
            return this.is_external_or_common_js_module()
SPEC

run "c12 bind_block_scoped_declaration asks the DISJUNCTION" <<SPEC
FILE $B
<<<OLD
            if this.is_external_or_common_js_module()
            {
                this.declare_module_member(n, symbol_flags, symbol_excludes)
                return
            }
>>>NEW
            if is_external_module
            {
                this.declare_module_member(n, symbol_flags, symbol_excludes)
                return
            }
SPEC

run "c13 is_implicitly_exported_jsdoc_declaration asks the DISJUNCTION" <<SPEC
FILE $B
<<<OLD
        if this.is_external_or_common_js_module() = false
            return false
        let k AstNode.kind_of(n)
>>>NEW
        if is_external_module = false
            return false
        let k AstNode.kind_of(n)
SPEC

run "c14 bind_source_file_if_external_module asks the DISJUNCTION" <<SPEC
FILE $B
<<<OLD
        if this.is_external_or_common_js_module()
        {
            this.bind_source_file_as_external_module()
            return
        }
>>>NEW
        if is_external_module
        {
            this.bind_source_file_as_external_module()
            return
        }
SPEC

run "c15 bind_common_js_type_exports runs for a CommonJS file too" <<SPEC
FILE $B
<<<OLD
            if this.is_external_or_common_js_module()
                set folds_type_exports: true
>>>NEW
            if is_external_module
                set folds_type_exports: true
SPEC

run "c16 the two CommonJS locals are declared" <<SPEC
FILE $B
<<<OLD
                if common_js_module_indicator <> null
                {
                    if this.is_unported() = false
                    {
                        this.declare_common_js_variable("module")
                        this.declare_common_js_variable("exports")
                    }
                }
>>>NEW
SPEC

run "c17 module carries a member called exports" <<SPEC
FILE $B
<<<OLD
            set ep.parent: s
            SymbolTable.set_entry(host, Symbol.get_members(host, s), ed, el, ep)
>>>NEW
            set ep.parent: s
SPEC

# ── group 3: the arms' own content ───────────────────────────────────────────

run "c18 module.exports = <entity name> is an ALIAS" <<SPEC
FILE $B
<<<OLD
        var flags: int SymbolFlagsProperty
        if Binder.expression_is_alias(AstNode.binary_right_of(n))
            set flags: SymbolFlagsAlias
>>>NEW
        var flags: int SymbolFlagsProperty
SPEC

run "c19 bindModuleExportsAssignment excludes NOTHING" <<SPEC
FILE $B
<<<OLD
        let s this.declare_symbol(Symbol.get_exports(host, cs), cs, n, flags, 0)
>>>NEW
        let s this.declare_symbol(Symbol.get_exports(host, cs), cs, n, flags, SymbolFlagsFunctionScopedVariableExcludes)
SPEC

run "c20 module.exports = x sets the value declaration" <<SPEC
FILE $B
<<<OLD
        if s = null
            return
        Binder.set_value_declaration(s, n)
    }
>>>NEW
        if s = null
            return
    }
SPEC

run "c21 exports.a is a FUNCTION-SCOPED VARIABLE, not a property" <<SPEC
FILE $B
<<<OLD
        var flags: int SymbolFlagsFunctionScopedVariable
        if AstNode.kind_of(n) = KindBinaryExpression
>>>NEW
        var flags: int SymbolFlagsProperty
        if AstNode.kind_of(n) = KindBinaryExpression
SPEC

run "c22 exports.a = <entity name> is an ALIAS" <<SPEC
FILE $B
<<<OLD
            if Binder.expression_is_alias(AstNode.binary_right_of(n))
                set flags: SymbolFlagsAlias
>>>NEW
            if Binder.expression_is_alias(AstNode.binary_right_of(n))
                set flags: SymbolFlagsFunctionScopedVariable
SPEC

run "c23 bindExportsOrObjectDefineProperty excludes function-scoped variables" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(Symbol.get_exports(host, cs), cs, n, flags, SymbolFlagsFunctionScopedVariableExcludes)
    }
>>>NEW
        this.declare_symbol(Symbol.get_exports(host, cs), cs, n, flags, 0)
    }
SPEC

run "c24 setCommonJSModuleIndicator refuses in an ES module" <<SPEC
FILE $B
<<<OLD
    procedure set_common_js_module_indicator(this, n: pointer[AstNode]) returns bool
    {
        if is_external_module
            return false
>>>NEW
    procedure set_common_js_module_indicator(this, n: pointer[AstNode]) returns bool
    {
SPEC

run "c25 the FIRST indicator wins — the module symbol is made once" <<SPEC
FILE $B
<<<OLD
        if common_js_module_indicator = null
        {
            set common_js_module_indicator: n
>>>NEW
        if true
        {
            set common_js_module_indicator: n
SPEC

run "c26 bind_call_expression runs only in a JavaScript file" <<SPEC
FILE $B
<<<OLD
            if Parser.is_in_js_file(n)
                this.bind_call_expression(n)
>>>NEW
            this.bind_call_expression(n)
SPEC

# ── group 4: the names these arms declare ────────────────────────────────────

run "c27 an exports property is named by the property ACCESS name" <<SPEC
FILE $B
<<<OLD
        if wants_left
        {
            let left AstNode.binary_left_of(n)
            let name Parser.get_element_or_property_access_name(left)
            if name <> null
                return name
            return left
        }
>>>NEW
        if wants_left
            return null
SPEC

run "c28 a defineProperty declaration is named by its SECOND argument" <<SPEC
FILE $B
<<<OLD
            if args.get_length() < 2
                return null
            return *(args.get_buffer() + 1)
>>>NEW
            if args.get_length() < 1
                return null
            return *(args.get_buffer() + 0)
SPEC

run "c29 an unusable access name falls back to the LEFT OPERAND, not to nothing" <<SPEC
FILE $B
<<<OLD
            if name <> null
                return name
            return left
>>>NEW
            if name <> null
                return name
            return null
SPEC

# ── group 5: the require predicate, conjunct by conjunct ─────────────────────

run "c30 a BINDING ELEMENT asks about its variable declaration" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(d) = KindBindingElement
        {
            let bp AstNode.parent_node_of(d)
            if bp = null
                return false
            set d: AstNode.parent_node_of(bp)
            if d = null
                return false
        }
>>>NEW
SPEC

run "c31 an EXPORTED require declaration is not an alias" <<SPEC
FILE $B
<<<OLD
        if this.has_syntactic_modifier(stmt, ModifierFlagsExport)
            return false
>>>NEW
SPEC

run "c32 a TYPED require declaration is not an alias" <<SPEC
FILE $B
<<<OLD
        if AstNode.type_of(d) <> null
            return false
>>>NEW
SPEC

run "c33 the require argument must be a STRING LITERAL for an alias" <<SPEC
FILE $B
<<<OLD
        Parser.is_require_call(initializer, true)
>>>NEW
        Parser.is_require_call(initializer, false)
SPEC

run "c34 a non-assignment declaration takes the value declaration from an assignment one" <<SPEC
FILE $B
<<<OLD
        if Binder.is_assignment_declaration(s.value_declaration)
        {
            if Binder.is_assignment_declaration(n) = false
            {
                set s.value_declaration: n
                return
            }
        }
>>>NEW
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl37-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl37-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl37-final.log | head -30
  exit 1
fi
