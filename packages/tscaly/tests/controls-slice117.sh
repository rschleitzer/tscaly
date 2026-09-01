#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice117.sh — the control battery for THE DESTRUCTURING DECLARATION.
#
# ★★★ THE ROW TO READ FIRST IS g23, because it is the one the battery did not find:
# STAGE 2 did, on ONE unit in 18 391, and the row exists to hold the fix in place.
# `check_identifier` skipped its deprecation block with an argument that was right
# about the PRODUCT and wrong about the CALL — `addDeprecatedSuggestion` can indeed
# never reach a C section, but `resolveAliasWithDeprecationCheck` in front of it
# calls **resolveAlias**, and resolving an alias to a module that is not there
# REPORTS TS2307. **A call is not a suggestion just because its result is.**
#
# ★★★ AND THE ROW THAT SAYS WHAT THIS CHAPTER IS IS g06. `const {a: x} = src`
# indexes by the PROPERTY name and declares the BINDING name, and those are the same
# node at every other site in this function — so a port that reads `name_of` instead
# of `property_name_or_name_of` is correct on every unrenamed destructuring in the
# corpus and wrong on exactly the shape the feature exists for.
#
# ★★★ THE VERDICTS — THIRTEEN OF TWENTY-FIVE GATE, measured on ONE corpus (1 383
# cases / 1 636 units, baseline diagcheck 1 635 consistent / 738 speaking / 1 964
# diagnostics, typegate 683 868 10824):
#
#   g01 five pins RED, 4 gates     g14 UNGATED
#   g02 UNGATED                    g15 diagcheck RED 5 + typegate
#   g03 UNGATED                    g16 UNGATED
#   g04 UNGATED                    g17 diagcheck RED 1 + diagpin
#   g05 UNGATED                    g18 diagcheck RED 4 + diagpin + typegate
#   g06 three pins RED, 2 gates    g19 five pins RED, diagcheck RED 3, 2 gates
#   g07 relpin RED + relgate       g20 UNGATED
#   g08 UNGATED                    g21 diagpin RED
#   g09 UNGATED                    g22 diagpin + typepin RED + typegate
#   g10 UNGATED                    g23 stopgate
#   g11 UNGATED                    g24 UNGATED
#   g12 diagcheck RED 1            g25 four pins RED, 2 gates
#   g13 diagcheck RED 1, 2 pins
#
# ★★★ THE ROW WORTH THE WHOLE FILE IS g17, AND IT ONLY GATES AFTER THE FIXTURE WAS
# REWRITTEN. Its first run was UNGATED on all sixteen instruments, because no fixture
# held a redeclaration whose two types are IDENTICAL AND STRUCTURED — the one shape
# where `isTypeIdenticalTo` runs into the relation's recursion and STOPS. Adding
# `var same2: I<{s:string}>` beside `declare var same2: I<{s:string}>` turned it, and
# what it now holds in place is the defect stage 2 found on 37 units:
# **a relation that could not answer is not a `no`.**
#
# ★★★ AND THE FIRST RUN'S TWELVE MISSES WERE NOT ALL FIXTURE GAPS — THREE OF THEM
# NAME A WALL THREE PHASES EARLIER. g09, g10 and g11 aim at the index-signature arm
# of getPropertyTypeForIndexType, and `check-grammar-index-signature` stops the walk
# at the FIRST node of any file containing an index signature (52 units at stage 2),
# so no source this port can check ever reaches that arm. The fixture is kept as the
# marker: the day the grammar check lands, three rows go red unrewritten.
#
# ★★ AND ONE MISS WAS AN INSTRUMENT DEFECT OF MY OWN — a loop that measured the
# fixtures' stop tags ran `packages/tscaly/tests/out/tscaly_types` from INSIDE the
# fixtures directory, so the binary was not found, the command substitution came back
# empty, and the shell's `${r:-COMPLETE}` printed COMPLETE for four fixtures that stop
# at their first node. **A default that stands in for "no output" cannot tell an empty
# answer from a missing program.**
#
# ★★ THE OTHER NINE UNGATED ROWS, one reason each. g02 — the resolvedType cache is
# only filled with optionality by an ambient destructured parameter, which stops one
# line earlier at `get-non-nullable-type`. g03 — the prelude only moves a type that
# CONTAINS undefined, and `{a:number}|undefined` stops at `get-reduced-union-type`.
# g04 — AccessFlagsAllowMissing is read at the tuple bounds check and at the
# `isObjectLiteralType` fall-through, and a destructuring of an ANNOTATED type reaches
# neither. g05 — the synthetic access only changes an answer where the flow graph
# narrows the property, and no fixture here narrows one. g08 — measured equal on its
# own input: widening `number | 2` and stripping undefined from `number | undefined`
# both give `number`, so the fork has no observable side on `{ b = 2 }: { b?: number }`.
# g14 — the class pair differs in a MODIFIER, not in optionality, and the optionality
# difference that would show is a parameter against a variable, which g13's exemption
# takes first. g16 — the filter only matters when a merged declaration is NOT
# variable-like AND its six interesting modifiers differ; every such merge in the
# corpus is reported earlier as a duplicate identifier. g20 — convertAutoToAny's only
# observable difference is type IDENTITY, and the identity relation cannot separate
# two intrinsic `any`s. g24 — ObjectFacts and FunctionFacts differ only in the
# `typeof` bits, and this slice's one reader asks EQUndefined/NEUndefined, which both
# carry identically.
#
# ★★ WHAT HAS NO ROW, one sentence each. Eleven of the stops this slice wrote have
# NO INPUT in either corpus and `stops.sh` says so in advance (§3.5v's rule that a
# row for an arm nothing reaches is not a measurement): every arm of
# get_property_type_for_index_type guarded by `access_expression <> null` — this
# slice's caller passes a property NAME, so an ElementAccessExpression never arrives
# — plus the intersection arms of find_applicable_index_info,
# is_string_index_signature_only_type and get_generic_object_flags (no intersection
# type is minted in this port), the deferral that would mint an IndexedAccess type,
# and getTotalFixedElementCount behind isGenericTupleType, which needs a VARIADIC
# element that getTupleElementFlags stops before building.
#
# Cost, MEASURED rather than estimated: on a stage-1 artifact tree the 25 rows plus
# baseline take about 55 minutes, i.e. a little over two minutes a row — the build
# dominates and the whole-corpus gates sweep 1 636 units each.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/checker_destructuring_object_type.ts \
$FIX/checker_destructuring_default_value.ts \
$FIX/checker_destructuring_missing_property.ts \
$FIX/checker_destructuring_index_signature.ts \
$FIX/checker_destructuring_empty_pattern.ts \
$FIX/checker_destructuring_nested.ts \
$FIX/checker_destructuring_accessibility.ts \
$FIX/checker_subsequent_variable_declaration.ts \
$FIX/checker_declaration_flags_identical.ts"
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

# g01 — the chapter's premise: the binding element's type back to a report. Every
# destructured binding, the accessibility walk and the indexed access go with it.
mk('g01.py',
   '''            if dk = KindBindingElement
                return this.get_type_for_binding_element(declaration)''',
   '''            if dk = KindBindingElement
            {
                this.record_unported("get-type-for-binding-element-parent", dk)
                return null
            }''')

# g02 — the cached resolvedType returned even when optionality was folded into it,
# so an optional property's binding element keeps its `| undefined`.
mk('g02.py',
   '''                    var optional false
                    if Checker.strict_null_checks()
                    {
                        if Checker.is_optional_declaration(node)
                            set optional: true
                    }
                    if optional = false
                        return resolved''',
   '''                    return resolved''')

# g03 — the undefined-stripping prelude removed, so destructuring a possibly
# undefined source leaves undefined in every element type.
mk('g03.py',
   '''                            if this.has_type_facts(it as ref[Type], TypeFactsEQUndefined) = false
                            {''',
   '''                            if false
                            {''')

# g04 — AccessFlagsAllowMissing never set, so a default value no longer excuses a
# property the source does not declare.
mk('g04.py',
   '''        if allow_missing
            set access_flags: access_flags | AccessFlagsAllowMissing''',
   '''        if false
            set access_flags: access_flags | AccessFlagsAllowMissing''')

# g05 — getFlowTypeOfDestructuring answering the declared type, i.e. the synthetic
# element access never built and the flow analyser never asked.
mk('g05.py',
   '''        let reference this.get_synthetic_element_access(node)
        if this.unported_mark() <> mark
            return null
        if reference = null
            return declared_type''',
   '''        let reference this.get_synthetic_element_access(node)
        if this.unported_mark() <> mark
            return null
        if true
            return declared_type''')

# g06 — the index taken from the BINDING name instead of the PROPERTY name, which
# is the same node except on a renamed element.
mk('g06.py',
   '''            let name Checker.property_name_or_name_of(declaration)
            if name = null
                return null
            let index_type this.get_literal_type_from_property_name(name as ref[AstNode])''',
   '''            let name AstNode.name_of(declaration)
            if name = null
                return null
            let index_type this.get_literal_type_from_property_name(name as ref[AstNode])''')

# g07 — the initializer union built over the RAW element type rather than over its
# non-undefined part, so `const {a = 1} = src` keeps undefined.
mk('g07.py',
   '''        let nu this.get_non_undefined_type(t as ref[Type])
        if this.unported_mark() <> mark
            return null''',
   '''        let nu t
        if this.unported_mark() <> mark
            return null''')

# g08 — the root-annotated fork taken the other way, so an annotated pattern widens
# from its default value instead of only stripping undefined.
mk('g08.py',
   '''        if root_annotated
        {
            ; "In strict null checking mode, if a default value of a non-undefined''',
   '''        if false
        {
            ; "In strict null checking mode, if a default value of a non-undefined''')

# g09 — the INDEX SIGNATURE arm of getPropertyTypeForIndexType removed, so a
# property found by an index signature is reported instead of typed.
mk('g09.py',
   '''                var index_info this.get_applicable_index_info(object_type, index_type)
                if this.unported_mark() <> mark
                    return null
                if index_info = null
                {
                    set index_info: this.get_index_info_of_type(object_type, string_type)
                    if this.unported_mark() <> mark
                        return null
                }''',
   '''                var index_info: ref[IndexInfo]? null''')

# g10 — isApplicableIndexType without its numeric-literal-name disjunct, so `{0: x}`
# no longer matches a number index signature.
mk('g10.py',
   '''            if (source.flags & TypeFlagsStringLiteral) <> 0
            {
                if Checker.is_numeric_literal_name(Checker.literal_text_of(source), Checker.literal_text_length_of(source))
                    return true
            }''',
   '''            if false
                return true''')

# g11 — findApplicableIndexInfo without its string fallback, so a string index
# signature no longer applies when nothing else does.
mk('g11.py',
   '''            if string_index_info <> null
            {
                if this.is_applicable_index_type(key_type, string_type)
                    return string_index_info
            }
            return null''',
   '''            return null''')

# g12 — getIndexedAccessTypeEx answering nothing where the reference answers the
# error type, so a failed access propagates as an absence instead of a type.
mk('g12.py',
   '''        if t = null
            return error_type
        t
    }''',
   '''        if t = null
            return null
        t
    }''')

# g13 — areDeclarationFlagsIdentical without its parameter/variable exemption.
mk('g13.py',
   '''        if lk = KindParameter
        {
            if rk = KindVariableDeclaration
                return true
        }
        if lk = KindVariableDeclaration
        {
            if rk = KindParameter
                return true
        }''',
   '''        if false
            return true''')

# g14 — areDeclarationFlagsIdentical without its optionality test.
mk('g14.py',
   '''        if Checker.is_optional_declaration(left) <> Checker.is_optional_declaration(right)
            return false''',
   '''        if false
            return false''')

# g15 — the interesting-modifier mask widened to EVERY modifier, so a difference in
# `export` or `declare` reports where the reference says nothing.
mk('g15.py',
   '''        let interesting ModifierFlagsPrivate | ModifierFlagsProtected | ModifierFlagsAsync | ModifierFlagsAbstract | ModifierFlagsReadonly | ModifierFlagsStatic''',
   '''        let interesting 0 - 1''')

# g16 — the IsVariableLike filter dropped from the merged-declaration loop, so a
# declaration of another KIND enters the modifier comparison.
mk('g16.py',
   '''                            if Checker.is_variable_like(dd)
                            {''',
   '''                            if true
                            {''')

# g17 — the secondary declaration's identity test read WITHOUT its stop guard, which
# is the state diagcheck refused: a relation that could not answer is taken for a
# `no` and every structured redeclaration reports TS2403.
mk('g17.py',
   '''                            let id_mark this.unported_mark()
                            let identical this.is_type_identical_to(symbol_type as ref[Type], declaration_type)
                            if this.unported_mark() = id_mark
                            {''',
   '''                            let id_mark this.unported_mark()
                            let identical this.is_type_identical_to(symbol_type as ref[Type], declaration_type)
                            if true
                            {''')

# g18 — errorNextVariableOrPropertyDeclarationMustHaveSameType without its code
# fork, so a property redeclaration reports the VARIABLE code.
mk('g18.py',
   '''        if nk = KindPropertyDeclaration
            set code: DiagSubsequent_property_declarations_must_have_the_same_type_Property_0_must_be_of_type_1_but_here_has_type_2
        if nk = KindPropertySignature
            set code: DiagSubsequent_property_declarations_must_have_the_same_type_Property_0_must_be_of_type_1_but_here_has_type_2''',
   '''        if false
            set code: DiagSubsequent_property_declarations_must_have_the_same_type_Property_0_must_be_of_type_1_but_here_has_type_2''')

# g19 — the secondary declaration comparing the SYMBOL's type with itself instead
# of with this node's own widened type, which is the fold the fork exists to prevent.
mk('g19.py',
   '''                    let declaration_type this.convert_auto_to_any(dt_raw as ref[Type])''',
   '''                    let declaration_type this.convert_auto_to_any(symbol_type as ref[Type])''')

# g20 — convertAutoToAny answering its argument, so the control-flow AUTO type
# reaches the identity tests in place of `any`.
mk('g20.py',
   '''        if t = auto_type
            return any_type''',
   '''        if false
            return any_type''')

# g21 — checkNonNullNonVoidType's void report removed, so `const {} = maybe` says
# nothing.
mk('g21.py',
   '''            this.error_on_node(node, DiagObject_is_possibly_undefined)''',
   '''            if false
                this.error_on_node(node, DiagObject_is_possibly_undefined)''')

# g22 — the binding element's accessibility walk removed, so destructuring a
# private property is silent.
mk('g22.py',
   '''                                            this.check_property_accessibility(node, is_super, false, parent_type as ref[Type], property as ref[Symbol])''',
   '''                                            if false
                                                this.check_property_accessibility(node, is_super, false, parent_type as ref[Type], property as ref[Symbol])''')

# g23 — check_identifier's alias resolution removed again, which is the state the
# stage-2 pass found: a merged import/variable reports its missing module once
# instead of twice.
mk('g23.py',
   '''        let target_symbol this.resolve_alias_with_deprecation_check(les, node)
        if this.unported_mark() <> ident_mark
            return null''',
   '''        let target_symbol: ref[Symbol]? null
        if false
            return null''')

# g24 — isFunctionObjectType answering TRUE for every object, which is the shape
# the arm had while it was one stop: every destructuring source then gets Function
# facts instead of Object facts.
mk('g24.py',
   '''        if m.signatures <> null
        {
            if (m.signatures as ref[Array[ref[Signature]?]]).get_length() <> (0 as size_t)
                return true
        }
        if m.members = null
            return false''',
   '''        if true
            return true
        if m.members = null
            return false''')

# g25 — checkPropertyAccessibility's binding-element arm back to a report, which is
# where slice 116 left it and where the note that named its own expiry stood.
mk('g25.py',
   '''        if k = KindBindingElement
            set error_node: Checker.property_name_or_name_of(node)''',
   '''        if k = KindBindingElement
        {
            this.record_unported("binding-element-property-name", KindBindingElement)
            return false
        }''')
MK

control "g01 the binding element's type back to a report"       $CHECKER "$PATCHDIR/g01.py"
control "g02 the cached type returned with its optionality"     $CHECKER "$PATCHDIR/g02.py"
control "g03 the undefined-stripping prelude removed"           $CHECKER "$PATCHDIR/g03.py"
control "g04 AllowMissing never set"                            $CHECKER "$PATCHDIR/g04.py"
control "g05 the destructuring's flow type never asked"         $CHECKER "$PATCHDIR/g05.py"
control "g06 the index taken from the binding name"             $CHECKER "$PATCHDIR/g06.py"
control "g07 the initializer union over the raw element type"   $CHECKER "$PATCHDIR/g07.py"
control "g08 the annotated-root fork taken the other way"       $CHECKER "$PATCHDIR/g08.py"
control "g09 the index-signature arm removed"                   $CHECKER "$PATCHDIR/g09.py"
control "g10 isApplicableIndexType without the numeric name"    $CHECKER "$PATCHDIR/g10.py"
control "g11 findApplicableIndexInfo without its fallback"      $CHECKER "$PATCHDIR/g11.py"
control "g12 getIndexedAccessTypeEx answering nothing"          $CHECKER "$PATCHDIR/g12.py"
control "g13 the parameter/variable exemption removed"          $CHECKER "$PATCHDIR/g13.py"
control "g14 the optionality test removed"                      $CHECKER "$PATCHDIR/g14.py"
control "g15 the modifier mask widened to everything"           $CHECKER "$PATCHDIR/g15.py"
control "g16 the IsVariableLike filter dropped"                 $CHECKER "$PATCHDIR/g16.py"
control "g17 the identity test read without its stop guard"   $CHECKER "$PATCHDIR/g17.py"
control "g18 the TS2717/TS2403 fork removed"                    $CHECKER "$PATCHDIR/g18.py"
control "g19 the secondary type compared with itself"           $CHECKER "$PATCHDIR/g19.py"
control "g20 convertAutoToAny answering its argument"           $CHECKER "$PATCHDIR/g20.py"
control "g21 checkNonNullNonVoidType's void report removed"     $CHECKER "$PATCHDIR/g21.py"
control "g22 the accessibility walk removed"                    $CHECKER "$PATCHDIR/g22.py"
control "g23 check_identifier's alias resolution removed"       $CHECKER "$PATCHDIR/g23.py"
control "g24 isFunctionObjectType answering true for objects"    $CHECKER "$PATCHDIR/g24.py"
control "g25 the binding-element accessibility arm re-stopped"   $CHECKER "$PATCHDIR/g25.py"
