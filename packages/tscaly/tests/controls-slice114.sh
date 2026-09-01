#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice114.sh — the control battery for THE ALIAS'S TYPE.
#
# ★★★ THE ROW TO READ FIRST IS g01, because it is the only one that restores a LINE
# THAT WAS NEVER WRITTEN rather than a decision this slice made. `initializeChecker`
# seeds `valueSymbolLinks.Get(unknownSymbol).resolvedType = errorType`; this port had
# the two seedings around it and not that one, and a comment two lines above claimed
# *"the unknownSymbol line between them is already this port's, in create()"*. It is
# not in create() and never was. What the absence costs is invisible until
# getTypeOfAlias exists: every alias to a module this harness cannot resolve ends at
# `getTypeOfSymbol(unknownSymbol)`, whose Property flag routes it to
# getTypeOfVariableOrParameterOrProperty — and there the reference ASSERTS a value
# declaration it does not have. Measured: the alias chapter alone moved the stage-1
# checker yardstick 448 -> 459, and this one line moved it 459 -> 496.
#
# ★★★ AND THE SLICE'S OTHER FOUR REPAIRS ARE THE SAME SHAPE — a stop whose stated
# reason had already expired:
#
#   g09  three `get-declaration-of-alias-symbol` stops, all of them reading "it needs
#        getDeclarationOfAliasSymbol". That function has been ported since slice 110.
#   g13  `get-immediate-aliased-symbol`, reading "it needs getTargetOfAliasDeclaration,
#        which this slice does not have". Ported since slice 110 as well.
#   g14  `get-type-from-type-alias-reference`'s CheckFlagsUnresolved arm, whose note
#        proved itself unreachable *by construction* from the one producer the
#        reference has — and named that producer as the thing that would expire it.
#   g15  typeToString's Any arm, reading "t.alias is not represented yet, and CANNOT
#        be". Both slots have been on `Type` since slice 66.
#
# ★★★ ONE FINDING HAS NO ROW BECAUSE IT IS A LANGUAGE TRAP AND NOT A DECISION: the
# Unresolved arm's last statement was written as a bare `e` rather than `return e`.
# An implicit return is the last expression of a FUNCTION BODY, never of a nested
# block, so the block fell through into the tail — which then reported a TS2315 the
# reference does not have AND filled the cache, so the same node answered a fresh
# type on the way out. Four units red with a diagnostic at a right span; a probe in
# the arm fired three times and a probe in the TAIL fired three times, which is what
# named it. There is no control for it because the fix is not a fork.
#
# ★★ ONE SENTENCE FOR WHAT IS NOT A ROW: reportCircularityError's ALIAS branch (TS2303)
# is written and has NO local gate — the shape that reaches it is `import a = b` whose
# own check stops one wall earlier, at `import-equals-internal-target`. A fixture that
# contains a construct is not a fixture that reaches it (§3.5ap), so none was kept.
#
# ★★★ THE VERDICTS — THIRTEEN OF EIGHTEEN GATE, measured on ONE corpus (1 349 cases /
# 1 602 units, baseline diagcheck 1 601 consistent / 694 speaking / 1 795 diagnostics,
# typegate 546 971 7574):
#
#   g01 diagcheck RED + four gates   g10 UNGATED
#   g02 stopgate + relgate + typegate g11 typegate
#   g03 stopgate + typegate          g12 typegate
#   g04 UNGATED                      g13 typegate
#   g05 UNGATED                      g14 UNGATED
#   g06 UNGATED                      g15 typegate
#   g07 diagcheck RED + typegate     g16 typegate
#   g08 diagcheck RED + typegate     g17 stopgate + relgate + typegate
#   g09 stopgate + callgate + typegate  g18 stopgate + typegate
#
# ★★★ FOUR OF THE FIVE UNGATED ROWS ARE ONE SENTENCE AND IT WAS PREDICTABLE BEFORE THEY
# RAN: under this harness an alias resolves to `unknownSymbol` IN ONE HOP. So the
# type-only WALK is always one iteration (g05, g06 remove a distinction only a chain can
# show), the VALUE fork's false side is never taken because unknownSymbol's flags are
# SymbolFlagsAll (g04), and `les` and `symbol` differ only for an EXPORTED alias (g10).
# §3.5v's "no input in either corpus", and `stops.sh` says so in advance.
#
# ★★★ THE FIFTH, g14, IS THE INTERESTING ONE AND IT IS NOT A HOLE: the errorTypes cache's
# product is IDENTITY, and nothing this port compares can see it. Two fresh types carrying
# the same alias PRINT the same, so the T section is blind to the difference by
# construction. It is kept — it is the reference's shape, and the moment a relation or a
# union reaches one of these types the pointer comparison is what decides — and the row
# stands as the MEASUREMENT that says so rather than being dropped.
#
# Cost: run it on a STAGE-1 artifact tree. Eighteen rows plus baseline is about twenty-five
# minutes; the whole-corpus gates sweep the tree they find, and at stage 2 that is
# 18 000 units a row.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/alias_value_type.ts \
$FIX/alias_unresolved_name.ts \
$FIX/alias_unresolved_property.ts \
$FIX/alias_type_only_use_site.ts \
$FIX/alias_export_assignment_type.ts"
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

# g01 — THE SLICE'S FIRST FINDING: the unknownSymbol seeding removed, i.e. the tree as
# it stood before this slice. Every alias to an unresolvable module goes back to a stop.
mk('g01.py',
   '''        let kl this.value_symbol_link_of(unknown_symbol)
        set kl.resolved_type: error_type''',
   '''        let kl this.value_symbol_link_of(unknown_symbol)''')

# g02 — getTypeOfAlias's `exportSymbol` made LAZY, i.e. computed inside the popped
# branch where its only reader is. The value is unused on every non-circular path, so
# this looks like a saving; getTargetOfAliasDeclaration REPORTS, and the reference's
# third TS2307 per specifier is exactly this call.
mk('g02.py',
   '''        let decl this.get_declaration_of_alias_symbol(symbol)
        if decl <> null
            set export_symbol: this.get_target_of_alias_declaration(decl as ref[AstNode])''',
   '''        let decl this.get_declaration_of_alias_symbol(symbol)''')

# g03 — getTypeOfAlias's VALUE fork forced to the errorType side: the target's type is
# never asked for, so an alias to something that resolves answers `any`.
mk('g03.py',
   '''            if (this.get_symbol_flags(ts) & SymbolFlagsValue) <> 0''',
   '''            if false''')

# g04 — the same fork forced the OTHER way: getTypeOfSymbol asked for a target with no
# value meaning, which is the recursion the reference's comment says this test prevents.
mk('g04.py',
   '''            if (this.get_symbol_flags(ts) & SymbolFlagsValue) <> 0''',
   '''            if true''')

# g05 — getTypeOnlyAliasDeclarationEx replaced by the non-Ex twin, i.e. ONE symbol
# instead of the walk. A chain whose type-only link is not the first alias stops
# reporting.
mk('g05.py',
   '''                            let tod this.get_type_only_alias_declaration_ex(result, SymbolFlagsValue)''',
   '''                            let tod this.get_type_only_alias_declaration(result)''')

# g06 — the Ex walk's MEANING test removed, so it walks past the symbol that already
# carries the meaning asked for and reports on a link the reference stops before.
mk('g06.py',
   '''            if (Symbol.flags_of(cur) & meaning) <> 0
                return null''',
   '''            if false
                return null''')

# g07 — IsValidTypeOnlyAliasUseSite answering FALSE always: every type-only alias named
# anywhere becomes a TS1361, including in an `implements` clause and a type query.
mk('g07.py',
   '''                        if this.is_valid_type_only_alias_use_site(el) = false''',
   '''                        if true''')

# g08 — the predicate's LAST term dropped, i.e. the NEGATION that carries almost every
# true answer. A use site that is not an expression at all stops being valid.
mk('g08.py',
   '''        if AstNode.is_expression_node(use_site)
            return false
        if Checker.is_shorthand_property_name_use_site(use_site)
            return false
        true''',
   '''        false''')

# g09 — THE SLICE'S SECOND REPAIR: checkIdentifier's alias arm back to a stop, i.e. the
# `declaration` rebind removed.
mk('g09.py',
   '''            if (Symbol.flags_of(les) & SymbolFlagsVariable) = 0
                set declaration: this.get_declaration_of_alias_symbol(symbol)''',
   '''            if (Symbol.flags_of(les) & SymbolFlagsVariable) = 0
                set declaration: null''')

# g10 — that arm asking `les` instead of `symbol`, which is the exported symbol rather
# than the one the name resolved to.
mk('g10.py',
   '''                set declaration: this.get_declaration_of_alias_symbol(symbol)''',
   '''                set declaration: this.get_declaration_of_alias_symbol(les)''')

# g11 — the ExportAssignment arm's widener swapped for the OUTER one, which computes the
# type from the DECLARATION where the reference computes it from the checked expression.
mk('g11.py',
   '''                    set result: this.widen_type_for_variable_like_declaration(et, declaration, false)''',
   '''                    set result: this.get_widened_type_for_variable_like_declaration(declaration, false)''')

# g12 — the unresolved-symbol path key reduced to the identifier TEXT, so `A.T` and
# `B.T` collapse into one symbol and the second name prints as the first.
mk('g12.py',
   '''        let path_len Checker.unresolved_path(host, parent_symbol, text, text_len, &path_data)''',
   '''        let path_len Checker.unresolved_path(host, null, text, text_len, &path_data)''')

# g13 — THE SLICE'S THIRD REPAIR: getImmediateAliasedSymbol back to a stop.
mk('g13.py',
   '''                    return this.get_immediate_aliased_symbol(parent_symbol as ref[Symbol])''',
   '''                    return null''')

# g14 — the errorTypes cache disabled: a FRESH type per visit, which is an identity
# question and not a speed one — every downstream comparison is a pointer comparison.
mk('g14.py',
   '''            let cached this.find_error_type(symbol, alias_args)
            if cached <> null
                return cached''',
   '''            let cached this.find_error_type(symbol, alias_args)''')

# g15 — THE SLICE'S FOURTH REPAIR: the printer's alias arm removed, so an unresolved
# name prints `any` again.
mk('g15.py',
   '''            if t.alias_symbol <> null
                return this.write_alias_type_reference(t, out)''',
   '''            if false
                return this.write_alias_type_reference(t, out)''')

# g16 — symbolToEntityNameNode's PARENT CHAIN dropped, so `A.T` prints as `T`.
mk('g16.py',
   '''        let parent Symbol.parent_of(symbol)
        if parent <> null
        {
            Checker.write_symbol_entity_name(parent as ref[Symbol], out)
            out.append("." as char)
        }''',
   '''        let parent Symbol.parent_of(symbol)''')

# g17 — THE SLICE'S FIFTH REPAIR: isErrorType back to its first disjunct. An
# alias-carrying `any` then stops behaving like errorType at all 49 sites, and the
# first one to answer differently is the property access.
mk('g17.py',
   '''        if t = error_type
            return true
        if (t.flags & TypeFlagsAny) = 0
            return false
        t.alias_symbol <> null''',
   '''        t = error_type''')

# g18 — the module-augmentation STOP removed, i.e. the tree as it stood when eight
# stage-2 units read as FAIL with a TS2664 missing rather than as UNPORTED.
mk('g18.py',
   '''        if this.file_has_module_augmentation()
        {
            this.record_unported("merge-module-augmentation", 0)
            return
        }''',
   '''        if false
        {
            this.record_unported("merge-module-augmentation", 0)
            return
        }''')
MK

control "g01 the unknownSymbol resolvedType seeding removed"        $CHECKER "$PATCHDIR/g01.py"
control "g02 getTypeOfAlias's exportSymbol made lazy"               $CHECKER "$PATCHDIR/g02.py"
control "g03 the alias's VALUE fork forced to errorType"            $CHECKER "$PATCHDIR/g03.py"
control "g04 the alias's VALUE fork forced to getTypeOfSymbol"      $CHECKER "$PATCHDIR/g04.py"
control "g05 the Ex type-only walk replaced by its one-symbol twin" $CHECKER "$PATCHDIR/g05.py"
control "g06 the Ex walk's meaning test removed"                    $CHECKER "$PATCHDIR/g06.py"
control "g07 IsValidTypeOnlyAliasUseSite answering FALSE"           $CHECKER "$PATCHDIR/g07.py"
control "g08 that predicate's negated last term dropped"            $CHECKER "$PATCHDIR/g08.py"
control "g09 checkIdentifier's alias arm not rebinding declaration" $CHECKER "$PATCHDIR/g09.py"
control "g10 that arm asking the EXPORTED symbol instead"           $CHECKER "$PATCHDIR/g10.py"
control "g11 the ExportAssignment arm using the outer widener"      $CHECKER "$PATCHDIR/g11.py"
control "g12 the unresolved path key without its parent chain"      $CHECKER "$PATCHDIR/g12.py"
control "g13 getImmediateAliasedSymbol back to a stop"              $CHECKER "$PATCHDIR/g13.py"
control "g14 the errorTypes cache disabled"                         $CHECKER "$PATCHDIR/g14.py"
control "g15 the printer's alias arm removed"                       $CHECKER "$PATCHDIR/g15.py"
control "g16 symbolToEntityNameNode without the parent chain"       $CHECKER "$PATCHDIR/g16.py"
control "g17 isErrorType back to its first disjunct"                $CHECKER "$PATCHDIR/g17.py"
control "g18 the module-augmentation stop removed"                  $CHECKER "$PATCHDIR/g18.py"
