#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice113.sh — the control battery for THE LIB AND THE NAME THAT IS NOT FOUND.
#
# ★★★ THE ROW TO READ FIRST IS g05, because it is the only one that restores a defect
# this port SHIPPED rather than a decision this slice made. `add_deep_clone_reparse`
# copies the ROOT of a reparsed type and SHARES its children, and §3.5bf argued that was
# safe because *"every predicate the BINDER asks of a parent answers the same"*. A SCOPE
# CHAIN IS THE PARENT CHAIN: `@template T` + `@typedef {T} Alias` resolves `T` through the
# shared identifier, whose parent still names the original JSDocTypeExpression, so the
# walk goes up the JSDoc comment instead of into the alias. It was invisible for as long
# as the miss was a stop and INVENTED a TS2304 on fifteen units the hour it became a
# report. §3.5p from the inside — a divergence justified by what one PHASE asks.
#
# ★★★ AND THE SLICE'S OTHER TWO REPAIRS ARE THE SAME SHAPE, a claim that expired when the
# wall behind it came down:
#
#   g03/g04  getCannotFindNameDiagnosticForName was a CONSTANT at both its call sites.
#            The message is chosen by the caller and consumed three functions down, where
#            it was a stop — so `console` came out TS2304 and not TS2584, and `Map` in a
#            type position TS2304 and not TS2583. §3.5ae exactly.
#   g17      report_type_argument_arity's own note said the reference *"FALLS THROUGH for
#            a JS one"* and then claimed the JS half was covered by the stop above it.
#            That stop is `missingAugmentsTag`, i.e. ExpressionWithTypeArguments ONLY; a
#            plain TypeReference in a JS file reports and RUNS ON. `/** @template T */
#            class C {}` with `/** @param {C} p */` is `C<any>` upstream and was `any`
#            here — two stage-2 units, and stage 1 cannot see either.
#
# ★★★ WHAT HAS NO ROW HERE AND IS AN INSTRUMENT REPAIR RATHER THAN A PORT ONE: the WALK
# was gated on `c.is_unported()` at three places. That is right for the DUMP — a T section
# printed past a stop claims a type nobody computed — and wrong for `--walk`, which
# computes no type at all, so the only report that can be standing is the CONSTRUCTOR's.
# Slice 110 recorded the resulting red on `fixtures_globals_conflicts` and reproduced it
# at the parent tree, which proves only that it was not that commit's; the lib turned ONE
# witness into NINE and that is the only reason it was diagnosed. `walkcheck.sh` is 0 of
# 1 590 for the first time. It has no row because battery-lib.sh carries no walkgate, and
# a pin belongs in the library rather than in one battery — the measurement above is the
# verdict instead.
#
# ★★ ONE SENTENCE FOR WHAT IS NOT A ROW: `checkAndReportErrorForInvalidInitializer` still
# cannot fire (its guard is written by the KindPropertyDeclaration arm §3.5ao omits), and
# `merge_symbol` is a chapter of its own — 10 stage-1 units stop at `merge-global-symbol`
# where the reference MERGES the lib's declaration with the unit's, and a row that patches
# a stop into a different stop measures the battery.
#
# ★★★ FIVE OF THE NINE PIN FILES WERE WRITTEN BY THE BATTERY'S FIRST RUN, WHICH IS THE
# HALF OF AN UNGATED ROW THAT NO VERDICT COLUMN SHOWS. That run gated 12 of 17 and the
# five that did not had **no input at stage 1** — not a proof of anything, just an
# absence: `checkAndReportErrorForExtendingInterface` and the namespace pair have zero
# arrivals in the whole stage-1 corpus, the feature-map branch needs a name that is BOTH
# a key AND a near miss, `isUncheckedJSSuggestion` needs a plain `.js` file, and the
# JavaScript arity fall-through was found at stage 2 in the first place. ★★And one of
# the five was a hole of a SHARPER kind: `checker_name_not_found_forks.ts` HAS the
# namespace shape and the walk stops four statements before reaching it — **a fixture
# that contains a construct is not a fixture that reaches it**, which is why each fork
# now has a file of its own. ★★A third trap cost a round: `let x = <identifier>` never
# resolves the identifier at all — `isNullOrUndefined` reports one line earlier — so the
# suggester's witnesses are EXPRESSION STATEMENTS.
#
# ★★★ THE VERDICTS — SEVENTEEN OF SEVENTEEN GATE on the second run, measured on ONE
# corpus (1 344 cases / 1 597 units), and the shape of the table is the slice's own:
#
#   g01 fifteen instruments        g07 diagcheck RED + diagpin
#   g02 kindgate + relgate +       g08 diagcheck RED + diagpin
#       stopgate + typegate        g09 diagcheck RED + diagpin
#   g03 diagcheck RED + diagpin +  g10 diagcheck RED + diagpin
#       typepin + typegate         g11 diagcheck RED + diagpin
#   g04 diagcheck RED              g12 diagcheck RED + diagpin
#   g05 diagcheck RED + stopgate   g13 diagcheck RED + diagpin + typepin + typegate
#       + typegate                 g14 diagcheck RED + diagpin + stopgate + typepin
#   g06 callgate + diagcheck RED +      + typegate
#       diagpin + relgate +        g15 diagcheck RED + typegate
#       stopgate + stoppin +       g16 diagcheck RED + diagpin + typepin + typegate
#       typegate                   g17 typepin + typegate
#
# ★★★ TWELVE OF THE SEVENTEEN ARE diagcheck RED AND NOT ONE OF THEM IS A LOST LINE.
# diagcheck's relation is a SUBSEQUENCE, so removing a fork can only make our output
# smaller — which is legal. Every one of these rows reddens because the fork BELOW the
# one it removed then reports a DIFFERENT CODE at the SAME SPAN: the chain's whole
# product is which of nine codes a miss gets, and the chain is what makes each link
# observable. ★g17 is the one row with no diagcheck: both sides report the TS2314 and
# only the RETURN differs, so the breakage is a TYPE at a right position — the shape
# slice 109's typegate checksum exists for.
#
# Cost: run it on a STAGE-1 artifact tree. The whole-corpus gates sweep the tree they
# find, and at stage 2 that is 18 000 units a row. Sixteen rows plus baseline is about
# fifteen minutes at stage 1.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/checker_lib_globals.ts \
$FIX/checker_name_not_found.ts \
$FIX/checker_name_not_found_forks.ts \
$FIX/checker_name_not_found_export.ts \
$FIX/checker_name_not_found_interface.ts \
$FIX/checker_name_not_found_namespace.ts \
$FIX/checker_name_not_found_suggestion.ts \
$FIX/checker_name_not_found_js.js \
$FIX/checker_jsdoc_missing_type_arguments.js"
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

# g01 — THE LIB NOT MERGED. The table falls back to the unit's own top-level locals,
# which is exactly where slice 104 left it, and every lib name misses again.
mk('g01.py',
   '''        if lib_file <> null
            this.merge_file_globals(lib_file as ref[AstNode], lib_b as ref[Binder], ambient)''',
   '''        if false
            this.merge_file_globals(lib_file as ref[AstNode], lib_b as ref[Binder], ambient)''')

# g02 — THE FILE ORDER REVERSED. The oracle's program is lib-then-unit; merging the
# unit first makes the unit's declaration the one a colliding global name resolves to,
# and the lib's the one that collides.
mk('g02.py',
   '''        if lib_file <> null
            this.merge_file_globals(lib_file as ref[AstNode], lib_b as ref[Binder], ambient)
        this.merge_file_globals(file as ref[AstNode], b, ambient)''',
   '''        this.merge_file_globals(file as ref[AstNode], b, ambient)
        if lib_file <> null
            this.merge_file_globals(lib_file as ref[AstNode], lib_b as ref[Binder], ambient)''')

# g03 — getCannotFindNameDiagnosticForName back to the constant at getResolvedSymbol.
mk('g03.py',
   '''SymbolFlagsValue | SymbolFlagsExportValue, this.get_cannot_find_name_diagnostic_for_name(node), true, false)''',
   '''SymbolFlagsValue | SymbolFlagsExportValue, DiagCannot_find_name_0, true, false)''')

# g04 — the same constant at resolveEntityName, which is the TYPE-position half.
mk('g04.py',
   '''                        let first Checker.get_first_identifier(name)
                        if first <> null
                            set message: this.get_cannot_find_name_diagnostic_for_name(first as ref[AstNode])''',
   '''                        let first Checker.get_first_identifier(name)
                        if first <> null
                            set message: DiagCannot_find_name_0''')

# g05 — THE SLICE'S OWN FINDING: the JSDoc shared-parent stop removed, i.e. the report
# made from a node whose parent chain never reaches the SourceFile.
mk('g05.py',
   '''        if Checker.source_file_of_node(error_location) = null
        {
            this.record_unported("jsdoc-reparse-shared-parent", meaning)
            return
        }''',
   '''        if false
        {
            this.record_unported("jsdoc-reparse-shared-parent", meaning)
            return
        }''')

# g06 — checkAndReportErrorForMissingPrefix removed: a static or instance member
# referenced without its prefix falls through to the plain miss.
mk('g06.py',
   '''            if this.check_and_report_error_for_missing_prefix(error_location, nd, nl)
                return''',
   '''            if false
                return''')

# g07 — checkAndReportErrorForExtendingInterface removed.
mk('g07.py',
   '''            if this.check_and_report_error_for_extending_interface(error_location)
                return''',
   '''            if false
                return''')

# g08 — checkAndReportErrorForUsingTypeAsNamespace removed.
mk('g08.py',
   '''            if this.check_and_report_error_for_using_type_as_namespace(error_location, nd, nl, meaning)
                return''',
   '''            if false
                return''')

# g09 — checkAndReportErrorForExportingPrimitiveType removed.
mk('g09.py',
   '''            if this.check_and_report_error_for_exporting_primitive_type(error_location, nd, nl)
                return''',
   '''            if false
                return''')

# g10 — checkAndReportErrorForUsingNamespaceAsTypeOrValue removed.
mk('g10.py',
   '''            if this.check_and_report_error_for_using_namespace_as_type_or_value(error_location, nd, nl, meaning)
                return''',
   '''            if false
                return''')

# g11 — checkAndReportErrorForUsingTypeAsValue removed.
mk('g11.py',
   '''            if this.check_and_report_error_for_using_type_as_value(error_location, nd, nl, meaning)
                return''',
   '''            if false
                return''')

# g12 — checkAndReportErrorForUsingValueAsType removed.
mk('g12.py',
   '''            if this.check_and_report_error_for_using_value_as_type(error_location, nd, nl, meaning)
                return''',
   '''            if false
                return''')

# g13 — the FEATURE MAP emptied. Its answer is a message ARGUMENT, but the branch
# RETURNS EARLY, so the key set is what decides between the caller's code and TS2552.
mk('g13.py',
   '''        if Checker.is_suggested_lib_name(nd, nl)
        {
            this.error_on_node_or_null(error_location, name_not_found_message)
            return
        }''',
   '''        if false
        {
            this.error_on_node_or_null(error_location, name_not_found_message)
            return
        }''')

# g14 — the SPELLING SUGGESTER disabled, so every TS2552 becomes the fallback code.
mk('g14.py',
   '''        if for_suggestion
            return this.get_suggestion_for_symbol_name_lookup(globals, name_data, name_len, meaning)''',
   '''        if for_suggestion
            return null''')

# g15 — the LEVENSHTEIN cutoff widened by a factor of three, i.e. the 0.4-of-the-length
# rule dropped: names that are not near misses become suggestions.
mk('g15.py',
   '''        var best_distance ((nl * 4) / 10) * 10 + 9''',
   '''        var best_distance ((nl * 12) / 10) * 10 + 9''')

# g16 — isUncheckedJSSuggestion answering FALSE, which turns every suggestion in a
# JavaScript file from a SUGGESTION (no C line) into an error.
mk('g16.py',
   '''            let unchecked_js this.is_unchecked_js_suggestion(error_location, suggestion)''',
   '''            let unchecked_js false''')

# g17 — THE SLICE'S THIRD REPAIR: the JavaScript arity FALL-THROUGH removed, i.e. the
# false reachability proof restored.
mk('g17.py',
   '''                let arity this.report_type_argument_arity(node, min_count, tp_count, is_js)
                if is_js = false
                    return arity''',
   '''                let arity this.report_type_argument_arity(node, min_count, tp_count, is_js)
                return arity''')
MK

control "g01 the LIB not merged into the globals table"            $CHECKER "$PATCHDIR/g01.py"
control "g02 the two files merged in the REVERSE order"            $CHECKER "$PATCHDIR/g02.py"
control "g03 the cannot-find-name message back to a constant"      $CHECKER "$PATCHDIR/g03.py"
control "g04 the same constant in the TYPE position"               $CHECKER "$PATCHDIR/g04.py"
control "g05 the JSDoc shared-parent stop removed"                 $CHECKER "$PATCHDIR/g05.py"
control "g06 checkAndReportErrorForMissingPrefix removed"          $CHECKER "$PATCHDIR/g06.py"
control "g07 checkAndReportErrorForExtendingInterface removed"     $CHECKER "$PATCHDIR/g07.py"
control "g08 checkAndReportErrorForUsingTypeAsNamespace removed"   $CHECKER "$PATCHDIR/g08.py"
control "g09 checkAndReportErrorForExportingPrimitiveType removed" $CHECKER "$PATCHDIR/g09.py"
control "g10 checkAndReportErrorForUsingNamespaceAsTypeOrValue removed" $CHECKER "$PATCHDIR/g10.py"
control "g11 checkAndReportErrorForUsingTypeAsValue removed"       $CHECKER "$PATCHDIR/g11.py"
control "g12 checkAndReportErrorForUsingValueAsType removed"       $CHECKER "$PATCHDIR/g12.py"
control "g13 the feature-map key list emptied"                     $CHECKER "$PATCHDIR/g13.py"
control "g14 the spelling suggester disabled"                      $CHECKER "$PATCHDIR/g14.py"
control "g15 the levenshtein cutoff widened threefold"             $CHECKER "$PATCHDIR/g15.py"
control "g16 isUncheckedJSSuggestion answering FALSE"              $CHECKER "$PATCHDIR/g16.py"
control "g17 the JavaScript arity fall-through removed"            $CHECKER "$PATCHDIR/g17.py"
