#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice112.sh — the control battery for the INFERRED RETURN TYPE.
#
# ★★★ THE ROW TO READ FIRST IS g11, because it is the only one that is a DEFECT THIS
# SLICE SHIPPED rather than a decision it made: `symbolToParameterDeclaration` was
# missing serializeTypeForDeclaration's `addUndefinedForParameter`, and nothing in this
# port could see it until a method's own type was printed — which is exactly what
# inferring the return type does. `method(a = 0, b)` came out `(a: number, b: any)`
# where the reference writes `a: number | undefined`. **A parameter that is
# INITIALIZED and yet NOT optional has no `?` to carry the meaning, so the TYPE has to.**
#
# ★★★ AND THE SLICE'S OTHER TWO REPAIRS ARE THE SAME SHAPE — A CLAIM THAT EXPIRED WHEN
# THE WALL BEHIND IT CAME DOWN, not code that was ever right:
#
#   g13  checkUnmatchedJSDocParameters was called UNREACHABLE on the strength of a gate
#        that does not exist. The note said check_source_element_worker *reports
#        `check-jsdoc-comments` and RETURNS for any node that [carries JSDoc]*;
#        check_jsdoc_comment stops for a @link and for nothing else. Two TS8024 lines
#        went missing the moment `conformance_jsdoc_jsdocParamTag` completed. §3.5p, and
#        the lesson is narrower than the usual one: **a proof about a GATE is only as
#        good as the gate's own condition, which this one named without reading.**
#   g12  the type printer answered `(Missing)` for the JSDoc reparser's `@this`
#        parameter — a synthesized Identifier with a name and no source range. The
#        printer was transcribing scanner.DeclarationNameToString, which is right in a
#        DIAGNOSTIC and wrong in the emit printer, where a synthesized node prints its
#        own text.
#
# ★★ WHAT HAS NO ROW, and it is one sentence rather than five (§3.5v-budget): the
# ASYNC and GENERATOR halves of this chapter. Every arm of both is a stop —
# checkAwaitedType, createPromiseReturnType, checkAndAggregateYieldOperandTypes,
# getIterationTypeOfGeneratorFunctionReturnType, GetPromisedTypeOfPromise — because
# each needs the awaited or the iteration dimension, and createPromiseType additionally
# needs the global `Promise` (§3.11). A row that patches a stop into a different stop
# measures the battery, not the port.
#
# ★★ AND NEITHER DOES THE WIDENING CONTEXT. getSiblingsOfContext, getPropertiesOfContext
# and getChildContext are reachable only from getWidenedType's UNION arm, i.e. only for
# a union that CONTAINS an object literal; the row that would price them is g07, which
# breaks the arm the corpus actually has.
#
# ★★★ TWO ROWS WERE WRITTEN AND THEN DROPPED, both for the same measured reason and
# both worth a sentence: **the empty-return arm's contextual fork and the constructor's
# TS2409 have no reachable input, and in each case the thing in the way is the RELATION.**
# The fork needs a contextual SIGNATURE, and every route to one here — `const f: () => T
# = () => {}` and every variant tried — goes through an assignability check that stops at
# `common-property-check`; the constructor arm calls that same relation itself, one line
# before the report. A row that patches an unreachable line measures the battery.
#
# ★★★ AND THE HOLE g12 FOUND IS THE BATTERY'S OWN PRODUCT. Its first run came back
# UNGATED on g12 — the synthesized-identifier repair — and the reason was not a corpus
# gap: **g13's stop, added in the same slice, had swallowed the only unit that
# witnesses g12.** `checker_jsdoc_reparse_this.js` carries a `@param` tag, the first
# version of that guard fired on any node that had one, and the fixture went UNPORTED.
# The guard is the reference's own skip test now, and the row is gated. **A stop added
# in one part of a slice can take the only input away from a repair made in another,
# and nothing but a control battery reports that.**
#
# ★★★ THE VERDICTS — THIRTEEN OF FOURTEEN GATE, measured on ONE corpus (1 335 cases /
# 1 588 units), and the fourteenth is the one whose ungatedness IS its finding:
#
#   g01 stopgate + typepin + typegate   g09 diagcheck RED + diagpin + relpin +
#   g02 fnpin + typepin + typegate          relgate + typepin + typegate
#   g03 fnpin + stopgate + typepin +    g11 typepin + typegate
#       typegate                        g12 typegate
#   g04 typepin + typegate              g13 stopgate + relgate + typegate
#   g06 stopgate + relgate + forkgate   g14 diagcheck RED + diagpin + typepin +
#       + typegate                          typegate
#   g07 stopgate + relgate + forkgate   g15 relgate
#       + typegate                      g16 stopgate + typegate
#   g08 UNGATED — see below
#
#   g08  THE MEMO'S EFFECT IS IDENTITY AND NOTHING HERE OBSERVES IDENTITY. Removing
#        `cachedTypes[Widened]` mints a second widened type for every object literal
#        widened twice; the dumps print NAMES, the pins print flags and counts, and
#        neither can tell two structurally equal anonymous types apart. It stays as a
#        row because the memo is still load-bearing — get_widened_type_of_object_literal
#        MINTS, so a caller comparing types by pointer would diverge, and this port has
#        several (filter_undefined_out's `core.Same`, the union interning).
#
# ★ TWO ROWS MOVE ONLY THE TYPEGATE'S CHECKSUM (g12, and g04 with the typepin) — a
# wrong NAME at a right position, which is the breakage no count can see and which
# slice 109's instrument exists for.
#
# Cost: run it on a STAGE-1 artifact tree. The whole-corpus gates sweep the tree they
# find, and at stage 2 that is 18 000 units a row. Thirteen rows plus baseline is about
# thirteen minutes at stage 1.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/checker_return_inferred.ts \
$FIX/checker_return_inferred_unit_widening.ts \
$FIX/checker_return_inferred_edges.ts \
$FIX/checker_return_expression_check.ts \
$FIX/checker_accessor_inferred_type.ts"
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

# g01 — the LITERAL WIDENING removed, so `function f() { return 1 }` answers `1`
# instead of `number`. It is the whole product of the isUnitType block.
mk('g01.py',
   '''            if Checker.is_unit_type(rt)
            {
                let contextual_signature this.get_contextual_signature_for_function_like_declaration(fn)''',
   '''            if false
            {
                let contextual_signature this.get_contextual_signature_for_function_like_declaration(fn)''')

# g02 — the strictNullChecks append dropped, so a function whose end is REACHABLE and
# which returns a value on some path answers `1` where the reference answers
# `1 | undefined`. The implicit `return undefined` is not in the syntax anywhere.
mk('g02.py',
   '''                    if present = false
                        types.add(undefined_type)''',
   '''                    if present = false
                        set present: true''')

# g03 — functionHasImplicitReturn read as FALSE, which is the same question one level
# up: it decides both the append above and whether the empty-types branch is taken.
mk('g03.py',
   '''        set agg.has_no_expression: fhir''',
   '''        set agg.has_no_expression: false''')

# g04 — mayReturnNever answering false, so `const f = function () { throw 1 }` answers
# `void` where the reference answers `never`. The kind list is the whole function.
mk('g04.py',
   '''        if k = KindFunctionExpression
            return true
        if k = KindArrowFunction
            return true
        if k = KindMethodDeclaration
            return Checker.kind_or_unknown(AstNode.parent_node_of(fn)) = KindObjectLiteralExpression
        false''',
   '''        false''')

# g06 — removeSubtypes' containment made UNCONDITIONAL, so a set that genuinely needs
# isTypeSubtypeOf is answered instead of stopped: the invention direction.
mk('g06.py',
   '''                if this.remove_subtypes_is_identity(type_set, has_object) = false''',
   '''                if false''')

# g07 — getWidenedType's OBJECT-LITERAL arm made the identity, which is the arm the
# whole row is: 91 arrivals over 49 units, every one at TypeFlagsObject.
mk('g07.py',
   '''            if Checker.is_object_literal_type(t)
                set result: this.get_widened_type_of_object_literal(t, context)''',
   '''            if false
                set result: this.get_widened_type_of_object_literal(t, context)''')

# g08 — the widened-type MEMO removed. Its effect is IDENTITY and not shape: two
# widenings of one object literal answer two different types.
mk('g08.py',
   '''            let cached this.widened_type_link_of(t).widened
            if cached <> null
                return cached''',
   '''            let cached this.widened_type_link_of(t).widened
            if false
                return cached''')

# g09 — checkReturnExpression's errorNode always the EXPRESSION, never the statement.
# The report is the same code at a different span, which is the shape diagcheck sees
# and no count does.
mk('g09.py',
   '''        if in_return_statement
        {
            if in_conditional_expression = false
                set error_node: node
        }''',
   '''        if false
        {
            if in_conditional_expression = false
                set error_node: node
        }''')

# g11 — THE SLICE'S OWN DEFECT: addUndefinedForParameter removed from the printer.
mk('g11.py',
   '''            if this.requires_adding_implicit_undefined(pd as ref[AstNode])''',
   '''            if false''')

# g12 — THE SLICE'S SECOND REPAIR: the synthesized identifier's own text dropped, so
# the printer falls back to the source range it does not have.
mk('g12.py',
   '''        if AstNode.pos_of(nm) = AstNode.end_of(nm)
        {
            out.append(AstNode.identifier_text_of(nm), AstNode.identifier_text_length_of(nm) as size_t)
            return true
        }''',
   '''        if false
        {
            out.append(AstNode.identifier_text_of(nm), AstNode.identifier_text_length_of(nm) as size_t)
            return true
        }''')

# g13 — THE SLICE'S THIRD REPAIR: the checkUnmatchedJSDocParameters stop removed, i.e.
# the false unreachability proof restored.
mk('g13.py',
   '''            if this.jsdoc_parameters_may_report(node)
                this.record_unported("check-unmatched-jsdoc-parameters", k)''',
   '''            if false
                this.record_unported("check-unmatched-jsdoc-parameters", k)''')

# g16 — the JSDoc-parameter guard WIDENED back to *does the node have a @param tag*,
# which is the version that swallowed g12's only witness. The row pins the narrowing:
# a tag whose name IS a parameter's name is skipped by the reference and must not stop.
mk('g16.py',
   '''            if Checker.parameter_names_hold(params, nm as ref[AstNode])
                    continue''',
   '''            if false
                    continue''')

# g14 — getTypeOfAccessors' else-if chain turned into three plain `if`s, so a class
# with an unannotated getter AND setter reports TS7032 and TS7033 where the reference
# reports only the first.
mk('g14.py',
   '''            if reported = false
            {
                if getter <> null
                {
                    if this.is_private_within_ambient(getter as ref[AstNode]) = false
                    {
                        this.error_on_node(getter as ref[AstNode], DiagProperty_0_implicitly_has_type_any_because_its_get_accessor_lacks_a_return_type_annotation)
                        set reported: true
                    }
                }
            }''',
   '''            if true
            {
                if getter <> null
                {
                    if this.is_private_within_ambient(getter as ref[AstNode]) = false
                    {
                        this.error_on_node(getter as ref[AstNode], DiagProperty_0_implicitly_has_type_any_because_its_get_accessor_lacks_a_return_type_annotation)
                        set reported: true
                    }
                }
            }''')

# g15 — the getter's borrowed SETTER annotation dropped, i.e. the arm slice 112 gave
# get_return_type_from_annotation. `get p() {...}` beside `set p(v: T)` then infers
# from the body where the reference reads T.
mk('g15.py',
   '''            return this.get_annotated_accessor_type(Checker.get_declaration_of_kind(sym as ref[Symbol], KindSetAccessor))''',
   '''            return null''')
MK

control "g01 the LITERAL WIDENING of a unit return type removed"   $CHECKER "$PATCHDIR/g01.py"
control "g02 the implicit undefined not appended to the returns"   $CHECKER "$PATCHDIR/g02.py"
control "g03 functionHasImplicitReturn read as FALSE"              $CHECKER "$PATCHDIR/g03.py"
control "g04 mayReturnNever answering false"                       $CHECKER "$PATCHDIR/g04.py"
control "g06 removeSubtypes' containment made UNCONDITIONAL"       $CHECKER "$PATCHDIR/g06.py"
control "g07 getWidenedType's OBJECT-LITERAL arm made the identity" $CHECKER "$PATCHDIR/g07.py"
control "g08 the widened-type MEMO removed"                        $CHECKER "$PATCHDIR/g08.py"
control "g09 checkReturnExpression's errorNode always the expression" $CHECKER "$PATCHDIR/g09.py"
control "g11 addUndefinedForParameter removed from the printer"    $CHECKER "$PATCHDIR/g11.py"
control "g12 the synthesized identifier's own text dropped"        $CHECKER "$PATCHDIR/g12.py"
control "g13 the checkUnmatchedJSDocParameters stop removed"       $CHECKER "$PATCHDIR/g13.py"
control "g14 getTypeOfAccessors' else-if made three plain ifs"     $CHECKER "$PATCHDIR/g14.py"
control "g15 the getter's borrowed SETTER annotation dropped"      $CHECKER "$PATCHDIR/g15.py"
control "g16 the JSDoc-parameter guard widened back"              $CHECKER "$PATCHDIR/g16.py"
