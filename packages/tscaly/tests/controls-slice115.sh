#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice115.sh — the control battery for THE ARRAY AND THE TUPLE.
#
# ★★★ THE ROWS TO READ FIRST ARE g11 AND g12, because both are defects the slice
# WROTE and the reference caught, and both come from reading a helper's NAME instead
# of the call site. g11: getTypeFromRestTypeNode applies getArrayElementTypeNode to
# `node.Type()`, and the first draft applied it to `node` — where that function has no
# RestType arm at all and answers null unconditionally, so `...T[]` denoted `T[]`
# instead of `T`, one level of array out, silently, at every rest element in the
# corpus. g12: all three tuple element wrappers pass `isProperty` TRUE, and the first
# draft called an `addOptionality` wrapper whose flag is FALSE — which puts the MISSING
# type where undefined belongs, a different type with the same printed name in most
# positions.
#
# ★★★ AND g13/g14 ARE ONE FINDING FROM TWO SIDES: slice 111's `wrote_paren_needing_type`
# was ONE BIT, justified by a containment proof over the arms that then existed — *of
# every node kind THIS printer can build, exactly two sit below TypeOperator*. An array
# emits its ELEMENT at TypePrecedencePostfix, one level ABOVE TypeOperator, so a UNION
# element must be parenthesized and the bit said the opposite. g13 puts the element back
# at TypeOperator and g14 puts the union arm's answer back to *no parens*; the reference
# prints `(A | null)[]` and the bit's answer is `A | null[]`, a different type.
#
# ★★★ TWELVE STOP TAGS DIED IN THIS SLICE AND g01 IS THE ONE THAT RESTORES THEM ALL.
# `new_object_type`'s Tuple arm was a report, and eleven other lines in checker.scaly
# named that report — or the missing global — as the reason they were a stop:
# get_base_types' Tuple arm, is_tuple_type, is_array_or_tuple_type,
# create_normalized_type_reference, get_parameter_count, has_effective_rest_parameter,
# get_min_argument_count, get_effective_rest_type, get_non_array_rest_type,
# widen_type_inferred_from_initializer, and the printer's three type-to-string stops.
# Every one of them is answered in the same commit, which is §3.5p's rule about a
# diagnostic that arrives later reading as a new bug.
#
# ★★ WHAT HAS NO ROW, in one sentence each: the TypePredicate arm and the CONSTRUCT half
# of the quick path are both unreachable behind a wall of another chapter
# (get-type-predicate-of-signature and is-constructor-accessible), so their fixtures are
# UNPORTED by construction and the stop TAG is the whole witness — a fixture that
# contains a construct is not a fixture that reaches it (§3.5ap). And the tuple target's
# numbered PROPERTIES and its `length` type are members rather than names, so nothing
# the T section prints can see them at stage 1; g03 and g04 are kept anyway as the
# measurement that says so.
#
# ★★★ THE VERDICTS — FIFTEEN OF TWENTY-FOUR GATE, measured on ONE corpus (1 361 cases /
# 1 614 units, baseline diagcheck 1 613 consistent / 708 speaking / 1 847 diagnostics,
# typegate 600 929 8585):
#
#   g01 tagpin+stoppin+typepin RED, 4 gates   g13 typepin RED + typegate
#   g02 typegate                              g14 typepin RED + typegate
#   g03 UNGATED                               g15 typepin RED + typegate
#   g04 UNGATED                               g16 typepin RED + typegate
#   g05 UNGATED                               g17 typepin RED + typegate
#   g06 stopgate + typegate                   g18 UNGATED
#   g07 typegate                              g19 UNGATED
#   g08 typegate                              g20 UNGATED
#   g09 typepin RED + typegate                g21 tagpin+stoppin+mempin+typepin RED, 2 gates
#   g10 UNGATED                               g22 UNGATED
#   g11 typepin RED + typegate                g23 typepin RED + typegate
#   g12 UNGATED                               g24 typepin RED + typegate
#
# ★★★ TWO ROWS COULD NOT FIRE IN THEIR FIRST DRAFT AND THE BATTERY IS WHAT SAID SO —
# both came back UNGATED ON ALL SIXTEEN, and neither is a property of the code. g13
# emitted the array element at TypePrecedenceTypeOperator, and a UNION is BELOW that, so
# the parentheses stayed; the level has to be one the union PASSES. g21 broke
# `get_type_arguments`' deferred arms, and nothing on the alias path asks a deferred
# reference for its type arguments — the site that decides is the CONSTRUCTION. **A
# refuter that cannot fire is worse than none, and a control aimed one call away from the
# decision measures the call it is aimed at.**
#
# ★★★ THE NINE THAT STAY UNGATED ARE FOUR DIFFERENT THINGS AND NOT ONE HOLE:
#
#   g03 g04 g05  the tuple target's numbered PROPERTIES and its `length` type are
#                MEMBERS, and nothing the T section prints can see a member at stage 1.
#                Predicted in this header before they ran; kept as the measurement.
#   g12          THE TWO SPELLINGS PROVABLY COINCIDE. `addOptionalityEx`'s isProperty
#                flag chooses between the MISSING type and undefined, and
#                `undefined_or_missing_type` is `undefined_type` unless
#                exactOptionalPropertyTypes is on — which it is not here. So the fix this
#                row reverts is the right CODE and a no-op ANSWER under these options,
#                which is what the row is for.
#   g10 g18      NO INPUT, and both are structural rather than a corpus gap. g10: a
#                `keyof` or `unique` operator wrapping an array or tuple never reaches
#                getArrayOrTupleTargetType, because the keyof arm REPORTS before it
#                resolves its operand. g18: no VARIADIC element survives to the printer —
#                checkTupleType stops on one and the normalizer reports.
#   g19 g20 g22  the wrong answer is never PRINTED. An overloaded or generic callee's unit
#                stops in the ordinary dispatch, so the quick path's invented answer has
#                no reader; and the ReadonlyArray fallback fires only for a `@noLib` unit
#                that declares `Array` and not `ReadonlyArray`, of which the corpus has
#                none.
#
# Cost: run it on a STAGE-1 artifact tree. Twenty-four rows plus baseline is about
# 50 minutes; the whole-corpus gates sweep the tree they find, and at stage 2 that is
# 18 000 units a row.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/array_type.ts \
$FIX/tuple_type.ts \
$FIX/literal_type.ts \
$FIX/type_operator_type.ts \
$FIX/quick_call_type.ts"
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

# g01 — the whole chapter's premise: new_object_type's Tuple arm back to a report. Every
# tuple type, the printer's tuple branch and the eleven readers that named it go with it.
mk('g01.py',
   '''        if (object_flags & ObjectFlagsTuple) <> 0
            return this.new_type(TypeFlagsObject, object_flags, sym, TypeData.Interface(InterfaceTypeData()))''',
   '''        if (object_flags & ObjectFlagsTuple) <> 0
        {
            this.record_unported("new-object-type-tuple", 0)
            return null
        }''')

# g02 — getTupleTargetType's `[...X[]] is just X[]` shortcut removed, so a one-element
# rest tuple mints a target instead of answering the array global.
mk('g02.py',
   '''            if (Checker.tuple_info_flags_at(infos, 0) & ElementFlagsRest) <> 0''',
   '''            if false''')

# g03 — createTupleTargetType's property guard asked of THIS element's flags instead of
# the ACCUMULATED ones, so an element after a rest gets a numbered property it has no
# fixed index for.
mk('g03.py',
   '''            if (combined_flags & ElementFlagsVariable) = 0
            {
                var sym_flags SymbolFlagsProperty''',
   '''            if (flags & ElementFlagsVariable) = 0
            {
                var sym_flags SymbolFlagsProperty''')

# g04 — `length` forced to plain `number` always: the literal union minLength..arity that
# carries a tuple's arity information is dropped.
mk('g04.py',
   '''        if (combined_flags & ElementFlagsVariable) <> 0
            set llinks.resolved_type: number_type''',
   '''        if true
            set llinks.resolved_type: number_type''')

# g05 — that union starting at ZERO instead of at minLength, so `[string, number?]`
# answers `0 | 1 | 2` where the reference answers `1 | 2`.
mk('g05.py',
   '''            var k min_length
            while k <= arity''',
   '''            var k 0
            while k <= arity''')

# g06 — createNormalizedTupleTypeEx's NonRequired early exit forced, i.e. never
# normalize. Optional and rest elements keep whatever layout the source wrote.
mk('g06.py',
   '''        if (combined & ElementFlagsNonRequired) = 0
            return this.create_type_reference(target, element_types, object_flags)''',
   '''        if true
            return this.create_type_reference(target, element_types, object_flags)''')

# g07 — the normalizer's "turn optional elements before the last required one into
# required" loop removed.
mk('g07.py',
   '''                if (ei.flags & ElementFlagsOptional) <> 0
                    out_infos.put(j as size_t, &TupleElementInfo^host(ElementFlagsRequired, ei.labeled_declaration))''',
   '''                if false
                    out_infos.put(j as size_t, &TupleElementInfo^host(ElementFlagsRequired, ei.labeled_declaration))''')

# g08 — the normalizer's rest-run fold removed: the elements between the first rest and
# the last optional-or-rest stay separate instead of becoming one rest element.
mk('g08.py',
   '''            if n.first_rest_index < n.last_optional_or_rest_index
            {
                let types n.types as ref[Array[ref[Type]?]]''',
   '''            if false
            {
                let types n.types as ref[Array[ref[Type]?]]''')

# g09 — getArrayOrTupleTargetType asking readonly of the NODE instead of its PARENT.
# `readonly string[]` is a TypeOperator wrapping the array, so the answer lives one level
# up and asking the array itself is always false.
mk('g09.py',
   '''        let readonly Checker.is_readonly_type_operator(AstNode.parent_node_of(node))''',
   '''        let readonly Checker.is_readonly_type_operator(node)''')

# g10 — is_readonly_type_operator accepting ANY operator, so `keyof T[]` and
# `unique symbol[]` read as readonly arrays.
mk('g10.py',
   '''        AstNode.type_operator_operator_of(n) = KindReadonlyKeyword
    }''',
   '''        true
    }''')

# g11 — THE SLICE'S FIRST DEFECT: getTypeFromRestTypeNode's array probe applied to the
# REST NODE instead of to its type. That function has no RestType arm, so it answers null
# unconditionally and `...T[]` denotes `T[]`.
mk('g11.py',
   '''        let element Checker.array_element_type_node_of(type_node)''',
   '''        let element Checker.array_element_type_node_of(node)''')

# g12 — THE SLICE'S SECOND DEFECT: the three tuple element wrappers passing isProperty
# FALSE, which routes getOptionalType to undefined where the reference uses the MISSING
# type.
mk('g12.py',
   '''        this.add_optionality_ex(t as ref[Type], true, true)''',
   '''        this.add_optionality_ex(t as ref[Type], false, true)''')

# g13 — THE PRECEDENCE FINDING from the ELEMENT side: an array's element emitted at
# TypePrecedenceUnion, which is the one level a UNION does not clear, so `(A | null)[]`
# loses its parentheses.
#
# ★★★ ITS FIRST DRAFT COULD NOT FIRE AND THE BATTERY SAID SO. It emitted the element at
# TypePrecedenceTypeOperator — and `TypePrecedenceUnion` (3) is still BELOW that (5), so
# the parentheses stayed and the row came back UNGATED ON ALL SIXTEEN. A refuter that
# cannot fire is worse than none: the level has to be one the union PASSES.
mk('g13.py',
   '''        let parens wrote_type_precedence < TypePrecedencePostfix
        if parens
            out.append("(" as char)
        out.append(scratch.to_string())
        if parens
            out.append(")" as char)
        true
    }

    ; typeReferenceToTypeNode's TUPLE branch''',
   '''        let parens wrote_type_precedence < TypePrecedenceUnion
        if parens
            out.append("(" as char)
        out.append(scratch.to_string())
        if parens
            out.append(")" as char)
        true
    }

    ; typeReferenceToTypeNode's TUPLE branch''')

# g14 — the same finding from the other side: the union arm's answer back to slice 111's
# one-bit `false`, i.e. *no parens anywhere*.
mk('g14.py',
   '''            set wrote_type_precedence: TypePrecedenceUnion
            return true''',
   '''            set wrote_type_precedence: TypePrecedenceNonArray
            return true''')

# g15 — a TUPLE element emitted at Postfix instead of Lowest, which is the array
# element's rule applied ten lines away: `[A | B, C]` gains parentheses the reference
# does not write.
mk('g15.py',
   '''                    else
                    {
                        if this.type_to_string(arg, out) = false
                            return false
                    }''',
   '''                    else
                    {
                        if this.write_postfix_type_operand(arg, out) = false
                            return false
                    }''')

# g16 — the tuple printer's readonly wrapper dropped, so `readonly [string, number]`
# prints as the mutable tuple.
mk('g16.py',
   '''        let readonly Checker.tuple_readonly_of(tgt)
        if readonly
            out.append("readonly ")''',
   '''        let readonly Checker.tuple_readonly_of(tgt)''')

# g17 — a LABELLED optional element's `?` written after the TYPE instead of after the
# name, i.e. the unlabelled spelling applied to the labelled shape.
mk('g17.py',
   '''                if (flags & ElementFlagsOptional) <> 0
                    out.append("?" as char)
                out.append(": ")''',
   '''                out.append(": ")''')

# g18 — the rest element's extra `[]` applied to VARIADIC elements too (`Variable`
# instead of `Rest`), which is the one place the two flags must not be folded.
mk('g18.py',
   '''                    if this.write_tuple_element_type(arg, (flags & ElementFlagsRest) <> 0, out) = false
                        return false
                }
                else
                {
                    if (flags & ElementFlagsOptional) <> 0''',
   '''                    if this.write_tuple_element_type(arg, (flags & ElementFlagsVariable) <> 0, out) = false
                        return false
                }
                else
                {
                    if (flags & ElementFlagsOptional) <> 0''')

# g19 — getSingleSignature's "exactly one" relaxed to "at least one", so an OVERLOADED
# callee takes the quick path and answers the FIRST overload's return type without ever
# looking at the arguments.
mk('g19.py',
   '''            if calls <> 1
                return null''',
   '''            if calls < 1
                return null''')

# g20 — getReturnTypeOfSingleNonGenericSignature's type-parameter test dropped, so a
# GENERIC callee answers its UNINSTANTIATED return type.
mk('g20.py',
   '''        if sig.type_parameters <> null
        {
            if (sig.type_parameters as ref[Array[ref[Type]?]]).get_length() <> 0
                return null
        }''',
   '''        if false
        {
            if (sig.type_parameters as ref[Array[ref[Type]?]]).get_length() <> 0
                return null
        }''')

# g21 — the DEFERRED array and tuple reference back to a stop, i.e. the whole
# `type A = string[]` family. It is the row that measures why the deferred pair had to
# land with this chapter rather than after it.
#
# ★★★ ITS FIRST DRAFT AIMED AT THE WRONG HALF AND CAME BACK UNGATED. It broke
# `get_type_arguments`' two arms — but nothing on the alias path ASKS for a deferred
# reference's type arguments (the printer reaches such a type through its ALIAS name),
# so the stop had no reader. The site that decides is the CONSTRUCTION, in
# getTypeFromArrayOrTupleTypeNode: with it back to a report the alias-of-array family
# stops where it stopped before the slice. **A control aimed one call away from the
# decision measures the call it is aimed at.**
mk('g21.py',
   '''                let deferred this.create_deferred_type_reference(tgt, node)
                if deferred = null
                    return null''',
   '''                let deferred this.create_deferred_type_reference(tgt, node)
                if true
                {
                    this.record_unported("create-deferred-type-reference", k)
                    return null
                }
                if deferred = null
                    return null''')

# g22 — get_global_readonly_array_type's fallback to globalArrayType removed, so a unit
# that declares `Array` and not `ReadonlyArray` names `readonly T[]` as `{}`.
mk('g22.py',
   '''        if t = empty_generic_type
            set t: this.get_global_array_type()
        set global_readonly_array_type: t''',
   '''        set global_readonly_array_type: t''')

# g23 — the tuple target cache ignoring the labelled DECLARATION, so `[a: string]` and
# `[b: string]` share one target and the second prints the first's label.
mk('g23.py',
   '''                                    if ai.labeled_declaration <> bi.labeled_declaration
                                        set same: false''',
   '''                                    if false
                                        set same: false''')

# g24 — getTupleElementInfo's labelled slot never written, which is the same wrong
# answer from the producing side: every element becomes unlabelled.
mk('g24.py',
   '''            if nk = KindNamedTupleMember
                set labeled: n''',
   '''            if false
                set labeled: n''')
MK

control "g01 new_object_type's Tuple arm back to a report"          $CHECKER "$PATCHDIR/g01.py"
control "g02 the [...X[]] shortcut removed"                         $CHECKER "$PATCHDIR/g02.py"
control "g03 the property guard on THIS element's flags"            $CHECKER "$PATCHDIR/g03.py"
control "g04 length forced to plain number"                         $CHECKER "$PATCHDIR/g04.py"
control "g05 length's literal union starting at zero"               $CHECKER "$PATCHDIR/g05.py"
control "g06 the normalizer never entered"                          $CHECKER "$PATCHDIR/g06.py"
control "g07 the optional-before-required promotion removed"        $CHECKER "$PATCHDIR/g07.py"
control "g08 the rest-run fold removed"                             $CHECKER "$PATCHDIR/g08.py"
control "g09 readonly asked of the NODE instead of the parent"      $CHECKER "$PATCHDIR/g09.py"
control "g10 is_readonly_type_operator accepting any operator"      $CHECKER "$PATCHDIR/g10.py"
control "g11 the rest node's array probe on the wrong node"         $CHECKER "$PATCHDIR/g11.py"
control "g12 the element wrappers passing isProperty FALSE"         $CHECKER "$PATCHDIR/g12.py"
control "g13 the array element emitted at Union precedence"       $CHECKER "$PATCHDIR/g13.py"
control "g14 the union arm back to slice 111's one bit"             $CHECKER "$PATCHDIR/g14.py"
control "g15 the tuple element emitted at Postfix"                  $CHECKER "$PATCHDIR/g15.py"
control "g16 the tuple printer's readonly wrapper dropped"          $CHECKER "$PATCHDIR/g16.py"
control "g17 a labelled element's ? after the type"                 $CHECKER "$PATCHDIR/g17.py"
control "g18 the rest [] applied to variadic too"                   $CHECKER "$PATCHDIR/g18.py"
control "g19 getSingleSignature's exactly-one relaxed"              $CHECKER "$PATCHDIR/g19.py"
control "g20 the generic-signature test dropped"                    $CHECKER "$PATCHDIR/g20.py"
control "g21 the deferred array/tuple reference back to a stop"    $CHECKER "$PATCHDIR/g21.py"
control "g22 the ReadonlyArray fallback removed"                    $CHECKER "$PATCHDIR/g22.py"
control "g23 the tuple cache ignoring the labelled declaration"     $CHECKER "$PATCHDIR/g23.py"
control "g24 getTupleElementInfo never writing the label"           $CHECKER "$PATCHDIR/g24.py"
