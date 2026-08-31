#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice109.sh — the control battery for `getTypeOfNode`'s chain.
#
# ★★★ THIS SLICE ADDED THE INSTRUMENT ITS OWN PRODUCT NEEDED, and that is the first
# thing to read here: none of the fourteen instruments batteries 103–108 shared can
# see the DUMP. `tags_of` greps the UNPORTED line and throws the rest away and
# `diags_of` asks for the C section, so the T SECTION — what the checker yardstick
# compares, and the whole product of an arm of getTypeOfNode — was invisible to every
# row of every battery. The TYPEPIN and the TYPEGATE are in battery-lib.sh, so every
# later battery asks them without being edited.
#
# ★★ TWO ARMS ARE NOT ROWS AND THAT IS MEASURED, NOT ASSUMED: the meta-property arm
# (KindMetaProperty) and the import-attributes arm (KindImportAttributes) have ZERO
# arrivals in the whole stage-1 corpus INCLUDING the five fixtures below — counted off
# the reference dumps of the 240 units this chapter was blocking. A row for an arm
# with no input is not a measurement, so they get this sentence instead of two rows.
# The qualified-name climb in `is_expression_node` is the same case at stage 1 and is
# rowed anyway (g11), because the corpus reaches it at stage 2.
#
# ★★★ THE VERDICTS, AND FOUR OF THE FIVE UNGATED ROWS WERE NOT PREDICTED — which is
# battery-lib's own definition of a hole, so each one is answered here rather than left
# with a colour. SIX ROWS GATE (g02 g03 g04 g06 g08 g09) and five do not:
#
#   g01  THE CHAIN'S ORDER is UNOBSERVABLE, and it is a CONTAINMENT PROOF rather than a
#        gap: `TypeDump.skip_for_type`'s FIRST line is `if is_part_of_type_node(node)
#        return true`, so the walk never asks getTypeOfNode about a type node at all.
#        The type-node arm is reachable only from getSymbolAtLocation's own callers, and
#        nothing in this corpus takes that door. **So the yardstick cannot see the order
#        of the two predicates, and no row of any battery could.**
#   g05  THE IMPLEMENTS FLAG has NO INPUT, and the wall is one arm earlier: the
#        class-extends arm is reached only with a non-nil `class_type`, and
#        `get_declared_type_of_class_or_interface` reports before that. Measured over the
#        corpus: `type-of-node-class-extends` fires ZERO times. ★★Of the chain's fourteen
#        report tags only THREE fire at stage 1 — `get-unresolved-symbol-for-entity-name`
#        14 events, `get-type-from-this-type-node` 7, `type-to-string-array` 1 — so eleven
#        of them are claims about stage 2 and about corpora this box does not have.
#   g07  THE ARRAY ARITY has no counterexample: exactly ONE unit of the corpus declares a
#        global `Array`, and it is `interface Array<T>`, arity 1. Widening the test cannot
#        change an answer where every candidate already passes it. The guard is kept
#        because it is the reference's and because `emptyGenericType` is what a wrong
#        arity answers, which no real target equals.
#   g10  THE BINDING PATTERN's answer is behind a wall too:
#        `get-type-for-binding-element-parent` fires 500 times, so
#        get_type_for_variable_like_declaration reports for both `n` and its parent and
#        the two spellings produce the same stop. ★It is rowed anyway because the arm is
#        one line and the wall is a chapter — the day that chapter lands, this row
#        starts gating without being edited.
#   g11  THE QUALIFIED-NAME CLIMB was PREDICTED ungated in the note below: kind 167 has
#        zero arrivals at stage 1. That one is a measurement and not a hole.
#
# ★★ WHAT THE NEW GATE BOUGHT, measured: g09 moves the TYPEPIN and the TYPEGATE CHECKSUM
# and NOTHING ELSE — no stop, no diagnostic, no count. It is exactly the breakage this
# family had no instrument for: a wrong NAME at a right position.
#
# Cost: 35 s of baseline plus 46-51 s per row — about 10 minutes for eleven rows.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/checker_type_of_node_statements.ts \
$FIX/checker_type_of_node_declaration.ts \
$FIX/checker_type_of_node_expression.ts \
$FIX/checker_type_of_node_type_declaration.ts \
$FIX/checker_type_of_node_binding.ts"
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

# g01 — the chain's ORDER: the expression test before the type-node test.
mk('g01.py',
   '''        if AstNode.is_part_of_type_node(n)
        {''',
   '''        if AstNode.is_expression_node(n)
            return this.get_regular_type_of_expression(n)
        if AstNode.is_part_of_type_node(n)
        {''')

# g02 — the FALLTHROUGH removed: the chain's tail reports instead of answering.
mk('g02.py',
   '''        ; The chain's own end: "if we get here, the node is not something we have a
        ; type for". Every plain STATEMENT reaches it, which is what the inventory
        ; used to admit three of by hand.
        error_type''',
   '''        this.record_unported("type-of-node", k)
        null''')

# g03 — is_in_expression_context's DEFAULT arm dropped (the recursion into the parent).
mk('g03.py',
   '''        if pk = KindShorthandPropertyAssignment
            return shorthand_object_assignment_initializer_of(parent) = n

        is_expression_node(parent)''',
   '''        if pk = KindShorthandPropertyAssignment
            return shorthand_object_assignment_initializer_of(parent) = n

        false''')

# g04 — is_declaration_name's IDENTITY test weakened to "the parent is a declaration".
mk('g04.py',
   '''        if is_declaration(p) = false
            return false
        name_of(p) = n''',
   '''        if is_declaration(p) = false
            return false
        true''')

# g05 — the isImplements flag inverted.
mk('g05.py',
   '''        set out_is_implements: heritage_clause_token_of(p) = KindImplementsKeyword''',
   '''        set out_is_implements: heritage_clause_token_of(p) <> KindImplementsKeyword''')

# g06 — the array-shorthand report removed: the branch this slice proved reachable.
mk('g06.py',
   '''        if this.target_is_global_array_type(tgt)
        {''',
   '''        if false
        {''')

# g07 — target_is_global_array_type's ARITY test dropped.
mk('g07.py',
   '''        if Checker.type_parameter_count_of(tgt) <> 1
            return false''',
   '''        if Checker.type_parameter_count_of(tgt) < 0
            return false''')

# g08 — get_regular_type_of_expression's hop to the parent removed.
mk('g08.py',
   '''        if Checker.is_right_side_of_qualified_name_or_property_access(e)
        {''',
   '''        if false
        {''')

# g09 — get_symbol_at_location's declaration-name prefix answers null.
mk('g09.py',
   '''            return parent_symbol
        }
        if Checker.is_literal_computed_property_declaration_name(node)''',
   '''            return null
        }
        if Checker.is_literal_computed_property_declaration_name(node)''')

# g10 — the BINDING-PATTERN arm asks about the node instead of its parent.
mk('g10.py',
   '''            let t this.get_type_for_variable_like_declaration(p as ref[AstNode], true, CheckModeNormal)''',
   '''            let t this.get_type_for_variable_like_declaration(n, true, CheckModeNormal)''')

# g11 — is_expression_node's QUALIFIED-NAME climb reduced to one level.
mk('g11.py',
   '''            var cur n
            while true
            {
                let p parent_node_of(cur)
                if p = null
                    return false
                if kind_of(p) <> KindQualifiedName
                    break
                set cur: p as ref[AstNode]
            }
            let p parent_node_of(cur)''',
   '''            let cur n
            let p parent_node_of(cur)''')
MK

control "g01 THE CHAIN'S ORDER — expression before type node"        $CHECKER "$PATCHDIR/g01.py"
control "g02 THE FALLTHROUGH — the tail reports instead of answering" $CHECKER "$PATCHDIR/g02.py"
control "g03 THE CONTEXT RECURSION — the default arm dropped"         $AST     "$PATCHDIR/g03.py"
control "g04 THE NAME IDENTITY — any child of a declaration is a name" $AST    "$PATCHDIR/g04.py"
control "g05 THE IMPLEMENTS FLAG — inverted"                          $AST     "$PATCHDIR/g05.py"
control "g06 THE ARRAY REPORT — removed"                              $CHECKER "$PATCHDIR/g06.py"
control "g07 THE ARRAY ARITY — the arity test dropped"                 $CHECKER "$PATCHDIR/g07.py"
control "g08 THE MEMBER HOP — get_regular_type_of_expression's parent" $CHECKER "$PATCHDIR/g08.py"
control "g09 THE DECLARATION-NAME PREFIX — answers null"              $CHECKER "$PATCHDIR/g09.py"
control "g10 THE BINDING PATTERN — asks the node, not its parent"      $CHECKER "$PATCHDIR/g10.py"
control "g11 THE QUALIFIED-NAME CLIMB — one level"                     $AST     "$PATCHDIR/g11.py"
