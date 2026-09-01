#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice118.sh — the control battery for THE ASSIGNABILITY RECURSION.
#
# ★★★ THE ROW TO READ FIRST IS g01, because it is the whole slice's premise and
# because the FRONTIER SAID IT WAS WORTH NOTHING. `frontier.sh` ranked
# `has-excess-properties` first under both granularities (+18 / 60 units); removing
# the stop and re-sweeping completed ZERO units, because `common-property-check`
# stands eleven lines below it in the SAME function and `recursive-type-related-to`
# eleven lines below that. g01, g02 and g03 put the three stops back one at a time,
# and reading them together is the measurement: each is silent on its own.
#
# ★★★ THE ROW WORTH THE FILE IS g11, and no corpus unit can produce it. With the
# error node forwarded into the nested relation ONE assignment reports TS2322 THREE
# TIMES — once per failing LEVEL — because the reference appends to a chain that is
# emitted once and this port emits at the line. diagcheck is a SUBSEQUENCE and
# refuses extras, and it was GREEN over all 1 635 corpus units: nothing out there
# reaches a nested failing relation through an error node. The fixture
# `relation_source_optional_property.ts` is what found it.
#
# ★★★ AND g05 IS THE ONE THAT COST A ROUND OF ITS OWN. Three of the port's list
# accessors — get_properties_of_type, get_signatures_of_type, get_index_infos_of_type
# — end in a `StructuredMembers` slot that is NULL when the type has none of that
# member kind, so their null carries two meanings and only the MARK separates them.
# Reading it as a failure made `let o = {}` unrelated to its own widened type: the
# corpus's commonest shape, answered `false` in silence.
#
# ★★ WHAT THIS BATTERY CANNOT GATE, and why it is stated rather than hidden. The
# chapter's ONE report — TS2353 — has no reachable input at stage 1: every route to
# it goes through `check_type_related_to_and_optionally_elaborate`, which asks the
# ELABORATOR first, and `elaborate-object-literal` stops there for every object
# literal. So no row here can redden a diagnostic through the excess check, and
# `relation_excess_property.ts` is kept as the marker for the slice that ports the
# elaborator. What the rows measure instead is the ANSWER: the typegate's matched
# count, the relgate's verdicts and the forkgate's routes.
#
# Cost, measured on this box: the rows plus baseline take about 45 minutes on a
# stage-1 artifact tree.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/relation_excess_property.ts \
$FIX/relation_excess_known.ts \
$FIX/relation_excess_widened_self.ts \
$FIX/relation_property_type_mismatch.ts \
$FIX/relation_missing_property.ts \
$FIX/relation_optional_property.ts \
$FIX/relation_source_optional_property.ts \
$FIX/relation_private_property.ts \
$FIX/relation_weak_type.ts \
$FIX/relation_weak_type_common.ts \
$FIX/relation_recursive_cycle.ts \
$FIX/relation_readonly_array_rest.ts \
$FIX/relation_identity_structured.ts"
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

# g01 — the excess check back to a stop. The frontier's head row, restored: on its
# own it must be SILENT on every instrument, because the two stops below it take
# every unit it releases.
mk('g01.py',
   '''                if this.has_excess_properties(source, target, relation, error_node)
                    return this.record_fork(source, target, 0, 0 - 1, fork_mark, false)''',
   '''                this.record_unported("has-excess-properties", target.flags)
                return this.record_fork(source, target, 0, 0 - 1, fork_mark, false)''')

# g02 — the common-property check back to a stop, with the excess check left live.
# Also silent on its own, for the same reason one line further down.
mk('g02.py',
   '''            if common
            {
                if this.has_common_properties(source, target, is_comparing_jsx_attributes) = false''',
   '''            if common
            {
                this.record_unported("common-property-check", target.flags)
                return this.record_fork(source, target, 1, 0 - 1, fork_mark, false)
            }
            if false
            {
                if this.has_common_properties(source, target, is_comparing_jsx_attributes) = false''')

# g03 — the recursion itself back to a stop, i.e. the tree as it stood before this
# slice from `is_related_to_ex`'s point of view. This is the row that moves, and the
# three together are what says the other two do not.
mk('g03.py',
   '''                set result: this.recursive_type_related_to(source, target, relation, error_node, intersection_state, recursion_flags)''',
   '''                this.record_unported("recursive-type-related-to", source.flags)''')

# g04 — the maybe stack never consulted, so a self-referential pair recurses until
# the 100-frame limit trips instead of being assumed related.
mk('g04.py',
   '''        if this.rel_maybe_has(source.id, target.id, intersection_state)
            return true''',
   '''        if false
            return true''')

# g05 — get_signatures_of_type's null read as a failure again. It is the defect the
# slice shipped and fixed within the hour: a target with NO call signatures is the
# ordinary object literal, and answering false there makes every `let o = {}`
# unrelated to its own widened type.
mk('g05.py',
   '''        let ts this.get_signatures_of_type(target, kind)
        if ts = null
            return true''',
   '''        let ts this.get_signatures_of_type(target, kind)
        if ts = null
            return false''')

# g06 — the same reading on the property list, which is the other half of that
# defect and reaches a different set of units.
mk('g06.py',
   '''        let props this.get_properties_of_type(target)
        if props = null
            return true
        let list props as ref[Array[ref[Symbol]?]]
        let n list.get_length() as int
        ; numericNamesOnly needs a tuple on BOTH sides and both are reported above.''',
   '''        let props this.get_properties_of_type(target)
        if props = null
            return false
        let list props as ref[Array[ref[Symbol]?]]
        let n list.get_length() as int
        ; numericNamesOnly needs a tuple on BOTH sides and both are reported above.''')

# g07 — getUnmatchedProperty reading a STOPPED lookup as a MISSING property, which
# is §3.5's `lookup_in_table` shape in the relation: it INVENTS a refusal for every
# name the global-object augment cannot answer about.
mk('g07.py',
   '''                    let mark this.unported_mark()
                    let sp this.get_property_of_type(source, Symbol.name_data_of(tp), Symbol.name_len_of(tp))
                    if this.unported_mark() <> mark
                        return null
                    if sp = null
                        return tp''',
   '''                    let sp this.get_property_of_type(source, Symbol.name_data_of(tp), Symbol.name_len_of(tp))
                    if sp = null
                        return tp''')

# g08 — the optional-property exemption removed from getUnmatchedProperty, so an
# optional target property the source lacks refuses the assignment.
mk('g08.py',
   '''                var ask require_optional_properties
                if ask = false
                {
                    if (Symbol.flags_of(tp) & SymbolFlagsOptional) = 0
                        set ask: true
                }''',
   '''                var ask true''')

# g09 — propertyRelatedTo's private arm removed, so two classes with identically
# named private properties become assignable.
mk('g09.py',
   '''        if private_side
        {
            if Symbol.value_declaration_of(source_prop) <> Symbol.value_declaration_of(target_prop)
                return false
        }''',
   '''        if false
        {
            if Symbol.value_declaration_of(source_prop) <> Symbol.value_declaration_of(target_prop)
                return false
        }''')

# g10 — propertyRelatedTo's optionality rule removed: an optional source property
# satisfies a required class member.
mk('g10.py',
   '''        if (Symbol.flags_of(source_prop) & SymbolFlagsOptional) = 0
            return true
        if (Symbol.flags_of(target_prop) & SymbolFlagsClassMember) = 0
            return true
        (Symbol.flags_of(target_prop) & SymbolFlagsOptional) <> 0''',
   '''        true''')

# g11 — THE ROW THE FIXTURE FOUND. The error node forwarded into the nested
# relation, so a failing property comparison reports once per LEVEL.
mk('g11.py',
   '''        ; The error node is not forwarded — see the readonly-array arm's note.
        this.is_related_to_ex(est as ref[Type], et, relation, null, intersection_state, RecursionFlagsBoth)''',
   '''        this.is_related_to_ex(est as ref[Type], et, relation, error_node, intersection_state, RecursionFlagsBoth)''')

# g12 — isKnownProperty without its index-signature disjunct, so a target with a
# string index signature no longer knows every name.
mk('g12.py',
   '''            if this.get_applicable_index_info_for_name(target_type, d, n) <> null
                return true''',
   '''            if false
                return true''')

# g13 — isWeakType's optionality test removed, so every object type with properties
# and no signatures is weak and the common-property check runs on all of them.
mk('g13.py',
   '''            if (Symbol.flags_of(row as ref[Symbol]) & SymbolFlagsOptional) = 0
                return false''',
   '''            if false
                return false''')

# g14 — hasExcessProperties' known-property read without its stop guard, which is
# the excess check's own copy of g07: a lookup that could not answer becomes an
# excess property and a TS2353 that the reference does not have.
mk('g14.py',
   '''                    let known_mark this.unported_mark()
                    let known this.is_known_property(target, pd, pn, is_comparing_jsx_attributes)
                    if this.unported_mark() <> known_mark
                        return false''',
   '''                    let known_mark this.unported_mark()
                    let known this.is_known_property(target, pd, pn, is_comparing_jsx_attributes)
                    if false
                        return false''')

# g15 — shouldCheckAsExcessProperty ignored, so a property inherited into the source
# type rather than written in the literal is checked for excess as well.
mk('g15.py',
   '''                if Checker.should_check_as_excess_property(prop, source.symbol) = false
                    set check: false''',
   '''                if false
                    set check: false''')

# g16 — the empty-object escape in hasExcessProperties removed, so `{}` as a target
# no longer accepts every literal.
mk('g16.py',
   '''            if is_comparing_jsx_attributes = false
            {
                if this.is_empty_object_type(target)
                    return false
            }''',
   '''            if false
            {
                if this.is_empty_object_type(target)
                    return false
            }''')

# g17 — the identity relation back to its old stop, i.e. slice 117's TS2403 wall
# restored at the door it used to stand in.
mk('g17.py',
   '''            return this.recursive_type_related_to(source, target, relation, null, IntersectionStateNone, recursion_flags)''',
   '''            this.record_unported("recursive-type-related-to", source.flags)
            return false''')

# g18 — the readonly-array arm removed, which is the one route the rest parameter's
# `T assignable to ReadonlyArray<any>` can take.
mk('g18.py',
   '''                    return this.is_related_to_ex(se as ref[Type], te as ref[Type], relation, null, intersection_state, RecursionFlagsBoth)''',
   '''                    this.record_unported("readonly-array-arm", target.flags)
                    return false''')

# g19 — the rest parameter's TS2370 asked without the mark guard, so a relation that
# could not answer reports.
mk('g19.py',
   '''        let mark this.unported_mark()
        let related this.is_type_assignable_to(reduced as ref[Type], target as ref[Type])
        if this.unported_mark() <> mark
            return
        if related = false''',
   '''        let mark this.unported_mark()
        let related this.is_type_assignable_to(reduced as ref[Type], target as ref[Type])
        if false
            return
        if related = false''')

# g20 — the implicit-any rest arm back to its early return, which is the
# PRE-EXISTING defect this slice un-hid: TS7019 is skipped for every untyped rest
# parameter, and it was invisible while the relation stopped.
mk('g20.py',
   '''        var t: ref[Type]? any_type
        if AstNode.kind_of(declaration) = KindParameter
        {
            if AstNode.dot_dot_dot_token_of(declaration) <> null
                set t: this.get_any_array_type()
        }
        if t = null
            return null''',
   '''        var t: ref[Type]? any_type
        if AstNode.kind_of(declaration) = KindParameter
        {
            if AstNode.dot_dot_dot_token_of(declaration) <> null
                return this.get_any_array_type()
        }
        if t = null
            return null''')

# g21 — the deeply-nested guard removed, so a chain of generic instantiations is
# compared structurally instead of being assumed to expand.
mk('g21.py',
   '''            if (rel_expanding_flags & ExpandingFlagsSource) = 0
            {
                if this.is_deeply_nested_type(source, RecursionFlagsSource, 3)
                    set rel_expanding_flags: rel_expanding_flags | ExpandingFlagsSource
            }''',
   '''            if false
            {
                if this.is_deeply_nested_type(source, RecursionFlagsSource, 3)
                    set rel_expanding_flags: rel_expanding_flags | ExpandingFlagsSource
            }''')

# g22 — isDeeplyNestedType's `t.id >= lastTypeId` test removed, which the reference
# names as the difference between a recursive instantiation and a type that merely
# appears three times.
mk('g22.py',
   '''                    if st.id >= last_type_id
                    {
                        set count: count + 1
                        if count >= max_depth
                            return true
                    }''',
   '''                    set count: count + 1
                    if count >= max_depth
                        return true''')

# g23 — the recursion flags ignored, both stacks pushed always. It is the depth
# MODEL and not a hint: a union arm would then count breadth as depth.
mk('g23.py',
   '''        if (recursion_flags & RecursionFlagsSource) <> 0
        {
            if rel_source_depth < (rel_source_stack.get_length() as int)''',
   '''        if true
        {
            if rel_source_depth < (rel_source_stack.get_length() as int)''')

# g24 — the same-target variance arm answering TRUE instead of stopping, so two
# instantiations of one generic relate whatever their arguments are.
mk('g24.py',
   '''                    this.record_unported("get-variances", src.object_flags)
                    return false''',
   '''                    return true''')

# g25 — the excess check's relation-error suppression undone: the relation error is
# emitted on top of TS2353, which is the invented line the reference's own
# suppression switch exists to prevent.
mk('g25.py',
   '''                if this.has_excess_properties(source, target, relation, error_node)
                    return this.record_fork(source, target, 0, 0 - 1, fork_mark, false)''',
   '''                if this.has_excess_properties(source, target, relation, error_node)
                {
                    if error_node <> null
                        this.report_relation_error(source, target, relation, error_node as ref[AstNode])
                    return this.record_fork(source, target, 0, 0 - 1, fork_mark, false)
                }''')
MK

control "g01 the excess check back to a stop"                   $CHECKER "$PATCHDIR/g01.py"
control "g02 the common-property check back to a stop"          $CHECKER "$PATCHDIR/g02.py"
control "g03 the recursion back to a stop"                      $CHECKER "$PATCHDIR/g03.py"
control "g04 the maybe stack never consulted"                   $CHECKER "$PATCHDIR/g04.py"
control "g05 a null signature list read as a failure"           $CHECKER "$PATCHDIR/g05.py"
control "g06 a null property list read as a failure"            $CHECKER "$PATCHDIR/g06.py"
control "g07 a stopped lookup read as a missing property"       $CHECKER "$PATCHDIR/g07.py"
control "g08 the optional-property exemption removed"           $CHECKER "$PATCHDIR/g08.py"
control "g09 the private-property arm removed"                  $CHECKER "$PATCHDIR/g09.py"
control "g10 the optionality rule removed"                      $CHECKER "$PATCHDIR/g10.py"
control "g11 the error node forwarded into the recursion"       $CHECKER "$PATCHDIR/g11.py"
control "g12 isKnownProperty without index signatures"          $CHECKER "$PATCHDIR/g12.py"
control "g13 isWeakType without its optionality test"           $CHECKER "$PATCHDIR/g13.py"
control "g14 the known-property read without its stop guard"    $CHECKER "$PATCHDIR/g14.py"
control "g15 shouldCheckAsExcessProperty ignored"               $CHECKER "$PATCHDIR/g15.py"
control "g16 the empty-object escape removed"                   $CHECKER "$PATCHDIR/g16.py"
control "g17 the identity relation back to its stop"            $CHECKER "$PATCHDIR/g17.py"
control "g18 the readonly-array arm removed"                    $CHECKER "$PATCHDIR/g18.py"
control "g19 the rest parameter asked without its mark guard"   $CHECKER "$PATCHDIR/g19.py"
control "g20 the implicit-any rest arm back to its early return" $CHECKER "$PATCHDIR/g20.py"
control "g21 the deeply-nested guard removed"                   $CHECKER "$PATCHDIR/g21.py"
control "g22 isDeeplyNestedType without the type-id test"       $CHECKER "$PATCHDIR/g22.py"
control "g23 the recursion flags ignored"                       $CHECKER "$PATCHDIR/g23.py"
control "g24 the variance arm answering true"                   $CHECKER "$PATCHDIR/g24.py"
control "g25 the relation error emitted on top of TS2353"       $CHECKER "$PATCHDIR/g25.py"
