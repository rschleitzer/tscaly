#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice29.sh — the slice-29 control battery, twenty-four of them.
#
# Slice 29 is the import/export ALIAS family: the four kinds the reference binds
# through one line, plus the four arms with a body of their own (the import
# clause, the export declaration, the export assignment and the namespace export
# declaration). Almost every claim in it is about WHICH TABLE a symbol lands in
# and WHAT IT IS CALLED, and both are things the symbols dump compares exactly —
# so a battery here is cheap and sharp.
#
# ★★★ THE ROW TO READ FIRST IS c5. Slice 28 shipped the alias branch of
# declareModuleMember and gated it as c13 UNGATED-*unreachable*, because nothing
# could produce an alias yet. This slice is the producer, so that row becomes a
# real gate — and c5 is it, re-broken in the same place. A claim parked as
# unreachable is a claim nobody has checked; the slice that lifts the condition
# owns the check (§3.5bx said so about is_in_top_level_context one slice ago, and
# it is the same rule).
#
# ★★ TWO ROWS COME BACK UNGATED and each says which of §3.5v's four reasons it is.
# c23 is the recursive arm of is_entity_name_expression: `export default a.b` is a
# PropertyAccessExpression, whose bind arm is still unported, so the unit reports
# rather than compares — UNGATED-because-unreachable. c24 is the export-specifier
# STRING name, where the port reports unported by construction and the control
# cannot make it answer differently.
#
# ★ Twenty fixtures came with the slice, and seven of them are one function's
# arms: `export as namespace X` has four DIAGNOSTIC arms and one that declares,
# and none of the five is reachable from the corpus, which contains no `.d.ts`
# with a UMD global. An unexercised arm is indistinguishable from a correct one,
# so each got a file.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice29.sh 2>&1 | tee /tmp/battery29.log
#
# 1 baseline + 24 controls + 1 verifying run = 26 runs.

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

# ── the four kinds that share one arm ────────────────────────────────────────

run "c1 an ImportSpecifier declares an alias" <<SPEC
FILE $B
<<<OLD
        if k = KindImportSpecifier
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
>>>NEW
        if false
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
SPEC

run "c2 the alias arm's FLAGS are Alias, not the value flags" <<SPEC
FILE $B
<<<OLD
        if k = KindNamespaceImport
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
>>>NEW
        if k = KindNamespaceImport
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsProperty, SymbolFlagsAliasExcludes)
SPEC

# ★ A NamespaceImport and a NamespaceExport share WrappedTypeData with a dozen
# wrapper kinds, so their name slot is spelled `inner` and reaching it needs an arm
# of its own in name_of (§3.5bb). These two rows are what makes that a measurement
# rather than a claim: without the arm getDeclarationName answers the internal
# `missing` name and the symbol is created outside every table.
run "c3 name_of reaches a NamespaceImport's name through the WRAPPED slot" <<SPEC
FILE $A
<<<OLD
            when nsimp: NamespaceImport
                return nsimp.inner
>>>NEW
            when nsimp: NamespaceImport
                return null
SPEC

run "c4 name_of reaches a NamespaceExport's name through the WRAPPED slot" <<SPEC
FILE $A
<<<OLD
            when nsexpc: NamespaceExport
                return nsexpc.inner
>>>NEW
            when nsexpc: NamespaceExport
                return null
SPEC

# ── which TABLE an alias lands in — slice 28's c13, now reachable ────────────

run "c5 an ExportSpecifier and an exported import= declare into EXPORTS" <<SPEC
FILE $B
<<<OLD
            if into_exports
            {
                let cs AstNode.symbol_of(container)
>>>NEW
            if false
            {
                let cs AstNode.symbol_of(container)
SPEC

run "c6 only an EXPORTED import= goes to exports; a plain one is a local" <<SPEC
FILE $B
<<<OLD
            if AstNode.kind_of(n) = KindImportEqualsDeclaration
            {
                if has_export_modifier
                    set into_exports: true
            }
>>>NEW
            if AstNode.kind_of(n) = KindImportEqualsDeclaration
            {
                set into_exports: true
            }
SPEC

# ── the import clause ────────────────────────────────────────────────────────

run "c7 an ImportClause declares only when it HAS a default name" <<SPEC
FILE $B
<<<OLD
        if AstNode.name_of(n) <> null
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
>>>NEW
        if true
            this.declare_symbol_and_add_to_symbol_table(n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
SPEC

# ── the export declaration ───────────────────────────────────────────────────

run "c8 a bare export* is collected under the container's ONE star symbol" <<SPEC
FILE $B
<<<OLD
        if clause = null
        {
            this.declare_symbol(Symbol.get_exports(host, cs), cs, n, SymbolFlagsExportStar, SymbolFlagsNone)
            return
        }
>>>NEW
        if clause = null
        {
            return
        }
SPEC

run "c9 export* as ns declares the CLAUSE, not the declaration" <<SPEC
FILE $B
<<<OLD
        if AstNode.kind_of(clause) = KindNamespaceExport
            this.declare_symbol(Symbol.get_exports(host, cs), cs, clause, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
>>>NEW
        if AstNode.kind_of(clause) = KindNamespaceExport
            this.declare_symbol(Symbol.get_exports(host, cs), cs, n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
SPEC

run "c10 the star symbol's name IS prefixed, unlike the other three" <<SPEC
FILE $B
<<<OLD
        if k = KindExportDeclaration
        {
            set *out_len: Binder.internal_name(host, "export", out_data)
            return
        }
>>>NEW
        if k = KindExportDeclaration
        {
            set *out_len: Binder.internal_name_unprefixed(host, "export", out_data)
            return
        }
SPEC

run "c11 an export* with no container symbol is an ANONYMOUS declaration" <<SPEC
FILE $B
<<<OLD
            this.bind_anonymous_declaration(n, SymbolFlagsExportStar, nd, nl)
            return
        }

        let clause AstNode.export_clause_of(n)
>>>NEW
            return
        }

        let clause AstNode.export_clause_of(n)
SPEC

# ── the export assignment ────────────────────────────────────────────────────

run "c12 export= and export default get DIFFERENT names" <<SPEC
FILE $B
<<<OLD
            if AstNode.is_export_equals_of(n)
                set *out_len: Binder.internal_name_unprefixed(host, "export=", out_data)
            else
                set *out_len: Binder.internal_name_unprefixed(host, "default", out_data)
>>>NEW
            set *out_len: Binder.internal_name_unprefixed(host, "export=", out_data)
SPEC

run "c13 both of those names are UNPREFIXED" <<SPEC
FILE $B
<<<OLD
            if AstNode.is_export_equals_of(n)
                set *out_len: Binder.internal_name_unprefixed(host, "export=", out_data)
>>>NEW
            if AstNode.is_export_equals_of(n)
                set *out_len: Binder.internal_name(host, "export=", out_data)
SPEC

run "c14 an export default of a NAME is an alias, of anything else a property" <<SPEC
FILE $B
<<<OLD
        if Binder.expression_is_alias(AstNode.expression_of(n))
            set flags: SymbolFlagsAlias
>>>NEW
        if false
            set flags: SymbolFlagsAlias
SPEC

run "c15 export= FORCES a value declaration where export default does not" <<SPEC
FILE $B
<<<OLD
        if AstNode.is_export_equals_of(n)
            Binder.set_value_declaration(s, n)
>>>NEW
        if false
            Binder.set_value_declaration(s, n)
SPEC

# ★★★ c16 CAME BACK UNGATED ON THE FIRST PASS AND THE REASON IS THE ROW'S WHOLE
# VALUE: for an ExportSpecifier the disjunct can never change the symbol's NAME.
# `ModuleExportNameIsDefault(name)` is `name.Text() == "default"`, and that is
# exactly the condition under which getDeclarationName already answers `default` —
# the two paths agree by construction, for a string-literal name as much as for an
# identifier. What the disjunct decides is the DIAGNOSTIC CODE on a conflict:
# `isDefaultExport` is handed to declareSymbolEx's duplicate report, where it
# turns TS2300 into TS2528. So the fixture the row needed is two of them
# (`binder_export_default_specifier_twice.ts`) and not one.
run "c16 export { a as default } IS a default export" <<SPEC
FILE $B
<<<OLD
                        if SymbolTable.names_equal(AstNode.identifier_text_of(en), AstNode.identifier_text_length_of(en), dd, dl)
                            set is_default_export: true
>>>NEW
                        if false
                            set is_default_export: true
SPEC

run "c17 two export defaults report 2528, not the plain duplicate 2300" <<SPEC
FILE $B
<<<OLD
                    if AstNode.is_export_equals_of(n) = false
                    {
                        set code: DiagA_module_cannot_have_multiple_default_exports
                        set multiple_defaults: true
                    }
>>>NEW
                    if false
                    {
                        set code: DiagA_module_cannot_have_multiple_default_exports
                        set multiple_defaults: true
                    }
SPEC

# ── the namespace export declaration ─────────────────────────────────────────
#
# The reference's body is a `switch { case … }`, i.e. a FIRST-MATCH chain, so the
# order of the three diagnostic arms is the answer and not a formatting choice.
# c18 swaps two of them; each of the two fixtures then reports the other's code.

run "c18 the diagnostic chain's ORDER decides which code a file gets" <<SPEC
FILE $B
<<<OLD
        if is_external_module = false
        {
            this.error_on_node(n, DiagGlobal_module_exports_may_only_appear_in_module_files)
            return
        }
        if is_declaration_file = false
        {
            this.error_on_node(n, DiagGlobal_module_exports_may_only_appear_in_declaration_files)
            return
        }
>>>NEW
        if is_declaration_file = false
        {
            this.error_on_node(n, DiagGlobal_module_exports_may_only_appear_in_declaration_files)
            return
        }
        if is_external_module = false
        {
            this.error_on_node(n, DiagGlobal_module_exports_may_only_appear_in_module_files)
            return
        }
SPEC

run "c19 the modifier report is NOT part of the chain — it still declares" <<SPEC
FILE $B
<<<OLD
        if AstNode.modifiers_of(n) <> null
            this.error_on_node(n, DiagModifiers_cannot_appear_here)
>>>NEW
        if AstNode.modifiers_of(n) <> null
        {
            this.error_on_node(n, DiagModifiers_cannot_appear_here)
            return
        }
SPEC

run "c20 the UMD global goes into GLOBAL EXPORTS, not the module's exports" <<SPEC
FILE $B
<<<OLD
        this.declare_symbol(this.get_global_exports(), fs, n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
>>>NEW
        this.declare_symbol(Symbol.get_exports(host, fs), fs, n, SymbolFlagsAlias, SymbolFlagsAliasExcludes)
SPEC

run "c21 that table is made ONCE and shared, so two of one name collide" <<SPEC
FILE $B
<<<OLD
        if global_exports = null
            set global_exports: SymbolTable.create(host)
>>>NEW
        set global_exports: SymbolTable.create(host)
SPEC

# ── GetNameOfDeclaration is not Node.Name() ──────────────────────────────────
#
# ★★★ THE DEFECT THIS SLICE FOUND, and it was found by the wide corpus rather
# than by reading: `export = x;` twice reported its duplicate across the whole
# STATEMENT where the reference reports at the `x`. Every one of the twenty-eight
# slices before this used `name_of` — a slot read — where the reference calls
# GetNameOfDeclaration, a function with three special cases on top of that slot,
# and the two agree on every kind that HAS a name slot. An ExportAssignment is the
# first kind reaching report_duplicate that has none.

run "c22 an export assignment is named by its EXPRESSION, not by a name slot" <<SPEC
FILE $B
<<<OLD
        if k = KindExportAssignment
        {
            let e AstNode.expression_of(n)
            if e = null
                return null
            if AstNode.kind_of(e) = KindIdentifier
                return e
            return null
        }
>>>NEW
        if k = KindExportAssignment
        {
            return null
        }
SPEC

# ── the two rows expected UNGATED, and which of the four reasons it is ────────
#
# ★ c23 is the RECURSIVE arm of is_entity_name_expression, which decides whether
# `export default a.b` is an alias or a property. It cannot be measured yet:
# a PropertyAccessExpression has a bind arm of its own and that arm is unported,
# so every unit carrying one REPORTS instead of comparing. The row exists so the
# claim is on the record as unmeasured rather than as checked; the slice that
# binds a property access owns it.
run "c23 (expected UNGATED-unreachable) a dotted name is an entity name too" <<SPEC
FILE $B
<<<OLD
        Binder.is_entity_name_expression(AstNode.expression_of(n))
>>>NEW
        false
SPEC

# ★ c24 is the STRING form of an export specifier's name — `export { x as "default" }`.
# This port stores no literal text, so the site REPORTS rather than answers, and a
# control cannot make it answer differently: both the patched and the unpatched port
# stop at the same marker. UNGATED-because-the-port-refuses, which is §3.5v's fourth
# reason arriving for a construct instead of a field.
run "c24 (expected UNGATED-refused) a STRING export name is reported, not guessed" <<SPEC
FILE $B
<<<OLD
                    else
                        this.record_unported("export-specifier-name-literal", AstNode.kind_of(en))
>>>NEW
                    else
                        set is_default_export: false
SPEC

echo
echo "################################################################"
bold "the verifying run — the report must reproduce the baseline byte for byte"
"$RUN" > /tmp/ctl29-final.log 2>&1 </dev/null
if cmp -s "$TSCALY_BASELINE" /tmp/ctl29-final.log; then
  green "IDENTICAL to the baseline report — the tree came back"
else
  red "the final report DIFFERS from the baseline:"
  diff "$TSCALY_BASELINE" /tmp/ctl29-final.log | head -30
  exit 1
fi
