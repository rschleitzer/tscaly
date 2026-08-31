#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice110.sh — the control battery for the ALIAS family.
#
# ★★★ THE FIRST THING TO READ HERE IS THAT THREE ROWS ARE THE SLICE'S OWN DEFECTS,
# each of which diagcheck caught and run.sh could not. g04, g05 and g06 restore the
# three wrong versions this slice actually shipped for an hour, so the fixes are
# pinned by the breakage that motivated them rather than by an argument:
#
#   g04  the report memo written at the REFERENCE'S place (the end of the function),
#        where this port's stop-guards return before it — TS2309 TWICE.
#   g05  the UMD `every` test ANSWERING where a `declare global` block's exports were
#        not merged — an invented TS2686.
#   g06  the early return before the module-exports branch put back — the lift's own
#        product, which is TS2323 and the second TS2307 of an `export * from`.
#
# ★★★ AND ONE SENTENCE REPLACES A DOZEN ROWS, which is §3.5v-budget's rule applied to
# a measurement rather than to an estimate: **under this harness no module specifier
# can ever resolve.** `tryFindAmbientModule` looks the QUOTED name up in globals,
# which needs the ambient module to be declared in a SCRIPT file — and any import
# makes the file a MODULE, where `declare module "x"` is an AUGMENTATION and never
# reaches globals at all. Probed, not argued: `declare module "amb" { … }` plus
# `import a = require("amb")` in one unit gets TS2664 on the ambient declaration from
# the reference itself, so even the `import =` spelling closes the door. So
# getExternalModuleMember's success path, canHaveSyntheticDefault,
# combineValueAndTypeSymbols, resolveESModuleSymbol's synthetic-default wrapper,
# getExportOfModule, resolveExportByName, getExportsOfModuleWorker's export-star
# recursion, reportNonExportedMember, errorNoModuleMemberSymbol and
# reportNonDefaultExport have ZERO input in EITHER corpus. Rows for them would be
# eleven measurements of nothing.
#
# ★★ WHAT THE FAMILY'S REACHABLE HALF IS, and it is what the rows below cover: the
# resolver's FAILURE path (TS2307, TS2591, TS2882, TS1202), resolveAlias coming to
# unknownSymbol, getSymbolFlags answering SymbolFlagsAll on it, checkAliasSymbol's two
# conflict reports, checkExportSpecifier, checkExternalModuleExports and the
# reference-marking walk.
#
# ★★★ THE VERDICTS — NINE OF TWELVE GATE, measured on ONE corpus (1 325 cases / 1 577
# units), and each of the three that do not carries a number rather than a colour:
#
#   g01 diagpin RED + typegate checksum      g07 diagcheck RED 3
#   g02 diagcheck RED 2 + diagpin RED        g08 UNGATED — see below
#   g03 stopgate 1577->1507 + typegate cks   g09 UNGATED — see below
#   g04 diagcheck RED 8                      g10 diagcheck RED 16 + diagpin RED
#   g05 diagcheck RED 1 + stopgate           g11 diagcheck RED 2
#   g06 diagpin RED + stopgate 7116->7093    g12 UNGATED — see below
#
#   g08  ZERO ARRIVALS, and the reason is one line of checkAliasSymbol: `if target =
#        unknown_symbol return`. Under this harness every IMPORT's target IS
#        unknownSymbol, so excludedMeanings is reachable only through an alias that
#        resolves LOCALLY — an export specifier — and the corpus's one such case
#        exports a `const`, which has no TYPE meaning to exclude. Probed with a
#        temporary `record_unported` at the line: 0 of 1 493 units.
#   g09  UNGATED BY CONSTRUCTION, and it is the argument for porting the marking
#        family at all: its product is a `referenced` BIT no yardstick of this port
#        reads. What it was ported FOR is its SIDE EFFECTS — resolveAlias,
#        getSymbolFlagsEx and getResolvedSymbol all report.
#   g12  ONE ARRIVAL, on `fixtures_checker_merged_declaration_alias` — a pin SLICE 65
#        wrote for exactly this hole, and whose own header predicts this verdict:
#        *"Answering DeclarationSpacesNone instead would be §3.5bk's silent wrong
#        answer: no space means no intersection means no report."* Both the right and
#        the wrong answer are silent in that unit, so no row can redden it; what the
#        slice buys is that the arm computes the union instead of answering None.
#
# ★★★ AND TWO OF THE THREE DEFECT ROWS MEASURED NOTHING ON THE FIRST RUN, which is why
# `alias_export_assignment_twice.ts` and `alias_umd_global.d.ts` exist: g04's shape
# (`export default 1; export = a;` with `a` undeclared) was in no fixture, and g05's
# lived only in a STAGE-2 unit. **The battery was blind on exactly the two rows that
# mattered most, and said UNGATED — which is indistinguishable from a passing gate.**
#
# Cost: run it on a STAGE-1 artifact tree. The five whole-corpus gates in
# battery-lib.sh sweep the tree they find, and at stage 2 that is 18 345 units a row.
# Twelve rows plus baseline is about 12 minutes at stage 1.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/alias_module_not_found.ts \
$FIX/alias_node_core_module.ts \
$FIX/alias_export_assignment_conflict.ts \
$FIX/alias_import_conflicts.ts \
$FIX/alias_export_specifier.ts"
battery_init "$@"
baseline

python3 - "$PATCHDIR" <<'MK'
import os, sys
D = sys.argv[1]
def mk(name, old, new, count=1):
    open(os.path.join(D, name), 'w').write(
        "import sys\n"
        "old = %r\n" % old +
        "new = %r\n" % new +
        "path = sys.argv[1]\n"
        "s = open(path).read()\n"
        "assert s.count(old) == %d, s.count(old)\n" % count +
        "open(path,'w').write(s.replace(old,new))\n")

# g01 — the resolver's ONLY report removed. Everything this family produces at stage 1
# hangs off it.
mk('g01.py',
   '''        if module_not_found_error <> 0
        {''',
   '''        if false
        {''')

# g02 — the node-core-module table answers false: TS2591 becomes TS2307.
mk('g02.py',
   '''        Checker.is_unprefixed_node_core_module(Slice[char](n, data))
    }''',
   '''        false
    }''')

# g03 — getSymbolFlagsEx's unknownSymbol answer weakened from SymbolFlagsAll to the
# flags accumulated so far. This is the line that makes an alias to an unresolvable
# module count as the symbol a lookup asked for.
mk('g03.py',
   '''            if t = unknown_symbol
                return SymbolFlagsAll''',
   '''            if t = unknown_symbol
                return flags''')

# g04 — THE SLICE'S FIRST DEFECT: the once-bit back at the reference's place.
mk('g04.py',
   '''        set links.exports_checked: true
        var ed null as pointer[char]''',
   '''        var ed null as pointer[char]''')

# g05 — THE SLICE'S SECOND DEFECT: the UMD `every` test answers instead of stopping.
mk('g05.py',
   '''                                    if this.file_has_global_augmentation()
                                        this.record_unported("unmerged-global-augmentation", 0)
                                    else
                                        this.error_on_node(el, DiagX_0_refers_to_a_UMD_global_but_the_current_file_is_a_module_Consider_adding_an_import_instead)''',
   '''                                    this.error_on_node(el, DiagX_0_refers_to_a_UMD_global_but_the_current_file_is_a_module_Consider_adding_an_import_instead)''')

# g06 — THE SLICE'S THIRD CHANGE: the early return before the module-exports branch.
mk('g06.py',
   '''        this.check_deferred_nodes()

        ; ★★★ SLICE 110 LIFTS THE SECOND OF THE TWO EARLY RETURNS SLICE 100 NAMED,''',
   '''        this.check_deferred_nodes()
        if this.is_unported()
            return

        ; ★★★ SLICE 110 LIFTS THE SECOND OF THE TWO EARLY RETURNS SLICE 100 NAMED,''')

# g07 — isNotOverload always true: an overload signature starts counting as a
# redeclaration.
mk('g07.py',
   '''        if signature_bearing = false
            return true
        AstNode.body_of(node) <> null''',
   '''        if signature_bearing = false
            return true
        true''')

# g08 — checkAliasSymbol's excludedMeanings loses its TYPE bit.
mk('g08.py',
   '''        if (sf & SymbolFlagsType) <> 0
            set excluded: excluded | SymbolFlagsType''',
   '''        if false
            set excluded: excluded | SymbolFlagsType''')

# g09 — the reference-marking walk removed. UNGATED BY CONSTRUCTION; see the header.
mk('g09.py',
   '''            if Checker.symbol_is_non_local(this, symbol)
                this.error_on_node(en, DiagCannot_export_0_Only_local_declarations_can_be_exported_from_a_module)
            else
                this.mark_linked_references(node, ReferenceHintExportSpecifier)''',
   '''            if Checker.symbol_is_non_local(this, symbol)
                this.error_on_node(en, DiagCannot_export_0_Only_local_declarations_can_be_exported_from_a_module)''')

# g10 — checkExportSpecifier's non-local test inverted: TS2661 fires on a local name
# and not on `undefined`.
mk('g10.py',
   '''            if Checker.symbol_is_non_local(this, symbol)
                this.error_on_node(en, DiagCannot_export_0_Only_local_declarations_can_be_exported_from_a_module)''',
   '''            if Checker.symbol_is_non_local(this, symbol) = false
                this.error_on_node(en, DiagCannot_export_0_Only_local_declarations_can_be_exported_from_a_module)''')

# g11 — the TS1202 arm's type-only guard dropped.
mk('g11.py',
   '''            if AstNode.is_type_only_of(node)
                return
            if (AstNode.flags_of(node) & NodeFlagsAmbient) <> 0
                return
            this.grammar_error_on_node(node, DiagImport_assignment_cannot_be_used_when_targeting_ECMAScript_modules_Consider_using_import_Asterisk_as_ns_from_mod_import_a_from_mod_import_d_from_mod_or_another_module_format_instead)''',
   '''            this.grammar_error_on_node(node, DiagImport_assignment_cannot_be_used_when_targeting_ECMAScript_modules_Consider_using_import_Asterisk_as_ns_from_mod_import_a_from_mod_import_d_from_mod_or_another_module_format_instead)''')

# g12 — getDeclarationSpaces' alias arms answer None again, which is what the four
# stops they replaced answered.
mk('g12.py',
   '''        if k = KindImportEqualsDeclaration
            return this.declaration_spaces_of_alias(node)''',
   '''        if k = KindImportEqualsDeclaration
            return DeclarationSpacesNone''')
MK

control "g01 THE RESOLVER'S REPORT — removed"                          $CHECKER "$PATCHDIR/g01.py"
control "g02 THE NODE-CORE TABLE — answers false"                      $CHECKER "$PATCHDIR/g02.py"
control "g03 getSymbolFlags ON unknownSymbol — not SymbolFlagsAll"     $CHECKER "$PATCHDIR/g03.py"
control "g04 THE ONCE-BIT AT THE REFERENCE'S PLACE — defect one"       $CHECKER "$PATCHDIR/g04.py"
control "g05 THE UMD TEST ANSWERING — defect two"                      $CHECKER "$PATCHDIR/g05.py"
control "g06 THE EARLY RETURN PUT BACK — the lift's product"           $CHECKER "$PATCHDIR/g06.py"
control "g07 isNotOverload — always true"                              $CHECKER "$PATCHDIR/g07.py"
control "g08 checkAliasSymbol's excludedMeanings — no TYPE bit"        $CHECKER "$PATCHDIR/g08.py"
control "g09 THE REFERENCE MARKING — removed (ungated by construction)" $CHECKER "$PATCHDIR/g09.py"
control "g10 THE NON-LOCAL EXPORT TEST — inverted"                     $CHECKER "$PATCHDIR/g10.py"
control "g11 THE TS1202 GUARD — type-only and ambient dropped"         $CHECKER "$PATCHDIR/g11.py"
control "g12 getDeclarationSpaces' ALIAS ARMS — answer None"           $CHECKER "$PATCHDIR/g12.py"
