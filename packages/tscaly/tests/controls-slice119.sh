#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice119.sh — the control battery for THE JSX ELEMENT.
#
# ★★★ THE ROW TO READ FIRST IS g10, AND IT IS THE ONE NO YARDSTICK FOUND. This
# chapter's answer rests on `getJsxNamespaceAt`, whose last act is a lookup in the
# GLOBALS table — and this port's globals are slice 104's *buildable half*, so a
# `declare global { namespace JSX { … } }` inside a module is absent from them for a
# reason that is the port's and not the source's. Answering *there is no JSX
# namespace* there made `getIntrinsicTagSymbol` emit TS7026 for a namespace the
# reference had found: seven invented diagnostics on one unit, which `diagcheck`
# caught as the single disagreeing unit of 1 649 while the checker yardstick, the
# walk and checktypes were all green. **The yardstick could not see it because the
# unit was UNPORTED, and a subsequence check is the only instrument that speaks on
# an unported unit.**
#
# ★★★ AND ITS FIRST FIX WAS THE IDENTITY, which is the lesson worth more than the
# row. The guard was written `if this.is_unported() return null` — and `null` is
# already this function's ordinary answer, *there is no JSX namespace*, so both
# branches returned the same value and the report came out unchanged. **A stop is
# something you SAY, not a value you return, wherever the null already means
# something.** g10 restores the identity version rather than the missing line,
# because that is the shape that actually shipped for twenty minutes.
#
# ★★★ THE SECOND ROW WORTH THE FILE IS g11, and its subject is a claim written in
# THIS FILE by an earlier slice. `empty_object_type`'s header says the port mints it
# through `new_object_type` rather than `new_anonymous_type`, that the missing
# resolved bit is *"confined to resolveStructuredTypeMembers, which reports"* — and
# this slice is the reader that reaches it, because `getSpreadType` asks
# `getPropertiesOfType` of the empty JSX object on the FIRST fold of every
# attributes list. The claim was true and it had an expiry date.
#
# ★★ WHAT THIS BATTERY CANNOT GATE, stated rather than hidden. Eight of the report
# sites this slice writes have NO input in the stage-1 corpus even with the twelve
# new fixtures: TS2602 (the JSX.Element precondition, dead by construction — see the
# chapter header), TS2604's fragment arm, TS2607, TS2639, TS2786, TS2710, TS6229 and
# TS2879. Four of them are behind the harness's `JsxEmitNone`, two behind walls in
# other chapters, and TS2602 behind `getJsxType`'s own answer. Their rows would be
# UNGATED with nothing moving, so they are not written; the chapter header names each
# with the reason instead.
#
# Cost, measured on this box: the rows plus baseline take about 50 minutes on a
# stage-1 artifact tree.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/jsx_intrinsic_element.tsx \
$FIX/jsx_intrinsic_unknown_tag.tsx \
$FIX/jsx_attribute_empty_expression.tsx \
$FIX/jsx_attribute_no_initializer.tsx \
$FIX/jsx_expression_comma.tsx \
$FIX/jsx_spread_child.tsx \
$FIX/jsx_namespaced_tag.tsx \
$FIX/jsx_hyphenated_tag.tsx \
$FIX/jsx_fragment_children.tsx \
$FIX/jsx_children_property_name.tsx \
$FIX/jsx_element_children_two_props.tsx \
$FIX/jsx_no_call_signatures.tsx \
$FIX/jsx_element_type_constraint.tsx \
$FIX/jsx_children_specified_twice.tsx \
$FIX/jsx_element_attributes_property.tsx \
$FIX/binder_jsx_attributes.tsx"
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

# g01 — the JSX ELEMENT arm back to a stop, i.e. the tree as it stood before this
# slice from check_expression's point of view. The slice's premise, and the largest
# of the five arms by units.
mk('g01.py',
   '''        if k = KindJsxElement
            return this.check_jsx_element(node, check_mode)''',
   '''        if k = KindJsxElement
        {
            this.record_unported("check-jsx-element", k)
            return null
        }''')

# g02 — the SELF-CLOSING arm back to a stop. Written separately from g01 because the
# two reach different units: an element with a closing tag also resolves the CLOSING
# tag's symbol, and a self-closing one does not.
mk('g02.py',
   '''        if k = KindJsxSelfClosingElement
            return this.check_jsx_self_closing_element(node, check_mode)''',
   '''        if k = KindJsxSelfClosingElement
        {
            this.record_unported("check-jsx-self-closing-element", k)
            return null
        }''')

# g03 — the FRAGMENT arm back to a stop. The third of the three that were live rows
# on the frontier; the expression and attributes arms never were, because nothing
# reaches them without one of these three.
mk('g03.py',
   '''        if k = KindJsxFragment
            return this.check_jsx_fragment(node)''',
   '''        if k = KindJsxFragment
        {
            this.record_unported("check-jsx-fragment", k)
            return null
        }''')

# g04 — TS17004 removed. checkJsxPreconditions' first arm is unconditional under
# this harness (compilerOptions.Jsx is JsxEmitNone), so this is the single commonest
# diagnostic the slice adds and the row should be the largest diagnostic delta here.
mk('g04.py',
   '''        this.error_on_node(error_node, DiagCannot_use_JSX_unless_the_jsx_flag_is_provided)''',
   '''        if false
            this.error_on_node(error_node, DiagCannot_use_JSX_unless_the_jsx_flag_is_provided)''')

# g05 — TS7026 removed. getIntrinsicTagSymbol's noImplicitAny arm, the second
# commonest, and the one that fires once per intrinsic tag rather than once per
# element.
mk('g05.py',
   '''        if Checker.no_implicit_any()
            this.error_on_node(node, DiagJSX_element_implicitly_has_type_any_because_no_interface_JSX_0_exists)''',
   '''        if false
            this.error_on_node(node, DiagJSX_element_implicitly_has_type_any_because_no_interface_JSX_0_exists)''')

# g06 — the CLOSING tag never resolved. The reference's comment says the call is
# there for rename and go-to-definition; its DIAGNOSTIC is what makes it observable,
# so this row is the difference between one TS7026 per element and two.
mk('g06.py',
   '''            if Checker.is_jsx_intrinsic_tag_name(tag)
            {
                var stopped false
                let ignored this.get_intrinsic_tag_symbol(closing as ref[AstNode], &stopped)
            }''',
   '''            if false
            {
                var stopped false
                let ignored this.get_intrinsic_tag_symbol(closing as ref[AstNode], &stopped)
            }''')

# g07 — getIntrinsicTagSymbol's memo never READ. ★★★THE ROW CORRECTED ITS OWN
# PREDICTION: it was written expecting every intrinsic tag to report twice, and it
# moves NOTHING on all fifteen instruments. The second caller —
# getStaticTypeOfReferencedJsxConstructor — sits behind `jsx-library-managed-
# attributes`, which fires on no unit of this corpus, so the function is asked
# exactly once per node. UNGATED, with the measurement as its argument, and the
# comment in checker.scaly was rewritten to say so.
mk('g07.py',
   '''        let links this.symbol_node_link_of(node)
        if links.resolved_symbol <> null
            return links.resolved_symbol
        let mark this.unported_mark()
        let intrinsic_elements_type this.get_jsx_type("IntrinsicElements", 17, node)''',
   '''        let links this.symbol_node_link_of(node)
        if false
            return links.resolved_symbol
        let mark this.unported_mark()
        let intrinsic_elements_type this.get_jsx_type("IntrinsicElements", 17, node)''')

# g08 — the JSX namespace memo never STORED on success, so every lookup re-resolves.
# It must be silent on every instrument: a memo may remove work, never an answer.
mk('g08.py',
   '''                            if links <> null
                                set (links as ref[JsxElementLink]).jsx_namespace: candidate
                            return candidate''',
   '''                            return candidate''')

# g09 — the memo's THIRD state dropped: a miss no longer writes unknownSymbol, so the
# `asked_and_missed` path never fires and the in-scope resolution runs on every ask.
# Silent for the same reason g08 is, and the pair is what says the three states are a
# statement about WORK rather than about answers.
mk('g09.py',
   '''            if links <> null
                set (links as ref[JsxElementLink]).jsx_namespace: unknown_symbol
        }''',
   '''            if false
                set (links as ref[JsxElementLink]).jsx_namespace: unknown_symbol
        }''')

# g10 — THE ROW THE HEADER NAMES. The globals-miss guard back to the IDENTITY it
# first shipped as: the test is still asked and both branches still answer null, so
# the report comes out on every unit whose JSX namespace this port could not build.
mk('g10.py',
   '''        if this.is_unported()
        {
            this.record_unported("jsx-namespace-in-incomplete-globals", SymbolFlagsNamespace)
            return null
        }
        null
    }''',
   '''        if this.is_unported()
            return null
        null
    }''')

# g11 — the two empty JSX object types minted through new_object_type again, i.e.
# the spelling the line above them still uses. getSpreadType then asks
# getPropertiesOfType of a type with no symbol and no resolved bit, and
# resolveAnonymousTypeMembers reports.
mk('g11.py',
   '''        set empty_jsx_object_type: this.new_anonymous_type(null, null, null, null, null)
        set empty_fresh_jsx_object_type: this.new_anonymous_type(null, null, null, null, null)''',
   '''        set empty_jsx_object_type: this.new_object_type(ObjectFlagsAnonymous, null)
        set empty_fresh_jsx_object_type: this.new_object_type(ObjectFlagsAnonymous, null)''')

# g12 — `<div hidden />` given `string` instead of the true literal. (`boolean_type`
# is the natural wrong answer and is NULL in this port, which would make the row a
# stop rather than a wrong type — so the row uses a type that exists.)
# checkJsxAttribute's second line, and the sugar the reference spells out.
mk('g12.py',
   '''        if initializer <> null
            return this.check_expression_for_mutable_location(initializer as ref[AstNode], check_mode)
        true_type''',
   '''        if initializer <> null
            return this.check_expression_for_mutable_location(initializer as ref[AstNode], check_mode)
        string_type''')

# g13 — the JsxAttribute arm of getTypeOfVariableOrParameterOrPropertyWorker back to
# its stop. It is what makes an attribute's own `T` line answerable at all, and the
# row is a claim about `getTypeOfNode`'s DECLARATION route rather than about the
# attributes type this slice also builds.
mk('g13.py',
   '''                if dk = KindJsxAttribute
                    set result: this.check_jsx_attribute(declaration, CheckModeNormal)''',
   '''                if false
                    set result: this.check_jsx_attribute(declaration, CheckModeNormal)''')

# g14 — isJsxIntrinsicTagName's HYPHEN disjunct dropped, so `<my-widget />` is read
# as a component reference and resolved as an expression. ★★It moved NOTHING on the
# battery's first run, because no unit of the corpus carries a hyphenated tag;
# `jsx_hyphenated_tag.tsx` was written for this row and nothing else.
mk('g14.py',
   '''        var i 0
        while i < n
        {
            if (*(d + i) as int) = 45
                return true
            set i: i + 1
        }
        false
    }''',
   '''        var i 0
        while i < n
        {
            if false
                return true
            set i: i + 1
        }
        false
    }''')

# g15 — its NAMESPACED disjunct dropped, which is the reference's own comment made
# false: `<a:b />` would become a component reference.
mk('g15.py',
   '''        if AstNode.kind_of(t) = KindJsxNamespacedName
            return true
        if AstNode.kind_of(t) <> KindIdentifier''',
   '''        if false
            return true
        if AstNode.kind_of(t) <> KindIdentifier''')

# g16 — checkGrammarJsxElement's duplicate-attribute report removed, TS17001.
mk('g16.py',
   '''            if SymbolTable.get(seen, nd, nl) <> null
                return this.grammar_error_on_node(name, DiagJSX_elements_cannot_have_multiple_attributes_with_the_same_name)''',
   '''            if false
                return this.grammar_error_on_node(name, DiagJSX_elements_cannot_have_multiple_attributes_with_the_same_name)''')

# g17 — its empty-initializer report removed, TS17000. The second of the two, and it
# fires on the INITIALIZER's span rather than on the name's.
mk('g17.py',
   '''                    if AstNode.expression_of(initializer as ref[AstNode]) = null
                        return this.grammar_error_on_node(initializer, DiagJSX_attributes_must_only_be_assigned_a_non_empty_expression)''',
   '''                    if false
                        return this.grammar_error_on_node(initializer, DiagJSX_attributes_must_only_be_assigned_a_non_empty_expression)''')

# g18 — checkGrammarJsxExpression removed whole, TS18007. The function is three
# lines and this is all of them. ★★It moved NOTHING on the battery's first run, and
# the reason was in the FIXTURE and not in the port: `jsx_expression_comma.tsx`
# PARENTHESISED its comma, and a ParenthesizedExpression is not an
# IsCommaExpression. The fixture contained the construct and did not reach the
# report — §3.5ap read from the fixture's side, and a row is the only thing that
# says so.
mk('g18.py',
   '''            if AstNode.binary_operator_kind(e as ref[AstNode]) = KindCommaToken
                return this.grammar_error_on_node(e, DiagJSX_expressions_may_not_use_the_comma_operator_Did_you_mean_to_write_an_array)''',
   '''            if false
                return this.grammar_error_on_node(e, DiagJSX_expressions_may_not_use_the_comma_operator_Did_you_mean_to_write_an_array)''')

# g19 — checkJsxExpression's spread-child report removed, TS2609. It is the one
# diagnostic in the chapter that belongs to the EXPRESSION and not to the element,
# and it needs the JsxExpression arm of dot_dot_dot_token_of — which this slice added
# and whose absence the fixture found.
mk('g19.py',
   '''                if this.is_array_type(ty) = false
                    this.error_on_node(node, DiagJSX_spread_child_must_be_an_array_type)''',
   '''                if false
                    this.error_on_node(node, DiagJSX_spread_child_must_be_an_array_type)''')

# g20 — the JSX fork removed from isSignatureApplicable, so a resolved element's
# attributes are never related to the parameter and the argument loop below walks the
# attributes NODE as if it were an argument expression.
mk('g20.py',
   '''        if Checker.is_jsx_call_like(node)
            return this.check_applicable_signature_for_jsx_call_like_element(node, signature, relation, check_mode, report_errors)''',
   '''        if false
            return this.check_applicable_signature_for_jsx_call_like_element(node, signature, relation, check_mode, report_errors)''')

# g21 — getEffectiveCallArguments' CHILDREN term dropped, so `<div>x</div>` is a
# zero-argument call where `<div />` already was. ★★PREDICTED UNGATED: an INTRINSIC
# tag returns its fake signature before resolveCall is reached, so the only route to
# this function is a COMPONENT tag — and every component tag in this corpus stops in
# front of it. The row is the claim that the two disjuncts are not interchangeable,
# held to a number that is zero.
mk('g21.py',
   '''            if k = KindJsxOpeningElement
            {
                if AstNode.list_count(AstNode.jsx_children_of(AstNode.parent_node_of(node))) <> 0
                    set has_argument: true
            }''',
   '''            if false
            {
                if AstNode.list_count(AstNode.jsx_children_of(AstNode.parent_node_of(node))) <> 0
                    set has_argument: true
            }''')

# g22 — hasCorrectArity's JSX clamp on the PARAMETER count dropped. ★★PREDICTED
# UNGATED, and for a reason that is arithmetic rather than reachability: the fake
# intrinsic signature has EXACTLY ONE parameter, so `effectiveParameterCount` is
# already 1 and the clamp is the identity on it. What the clamp is for — the
# reference's *"class may have argumentless ctor functions"* — needs a class
# component, which stops.
mk('g22.py',
   '''            if AstNode.list_count(args) <> 0
                set effective_parameter_count_jsx: 1''',
   '''            if false
                set effective_parameter_count_jsx: 1''')

# g23 — getContextNode's JsxAttributes arm removed, so the contextual type is pushed
# on the attributes list instead of on the whole element. ★★PREDICTED UNGATED: the
# arm is the IDENTITY on a self-closing element by its own guard, and the only reader
# of the moved entry is `findContextualNode` under
# `getContextualJsxElementAttributesType` — which needs an OPENING element whose
# attributes have a contextual type, i.e. a component. The arm is written because the
# note it replaced named this slice as its expiry, not because a unit shows it.
mk('g23.py',
   '''        this.push_contextual_type(Checker.get_context_node(node), contextual_type, false)''',
   '''        this.push_contextual_type(node, contextual_type, false)''')

# g24 — getJsxType answering NULL on a miss instead of errorType. It is the single
# decision the whole chapter's answer rests on: a null here turns the ordinary
# answer — *there is no JSX namespace, the element's type is the error type* — into a
# stop, and every JSX unit in the corpus goes unported.
mk('g24.py',
   '''        error_type
    }

    function get_jsx_element_type_at(this, location: ref[AstNode]?) returns ref[Type]?''',
   '''        null
    }

    function get_jsx_element_type_at(this, location: ref[AstNode]?) returns ref[Type]?''')

# g25 — getNameFromJsxElementAttributesContainer's ZERO-property answer read as
# MISSING. The three states are the reference's and the difference between the first
# two is exactly this line: an empty container means *the attributes type is the
# element instance type*, not *there is no container*. ★★PREDICTED UNGATED, and the
# shape that would move it is known: a `JSX.ElementChildrenAttribute` or
# `ElementAttributesProperty` declared with NO members. No unit of the corpus and no
# fixture has one — `jsx_children_property_name.tsx` declares exactly one member,
# which is the count-of-1 arm — so the row measures the transcription and not a
# reachable answer.
mk('g25.py',
   '''        ; empty name and not the MISSING verdict.
        if count = 0
            return true''',
   '''        ; empty name and not the MISSING verdict.
        if count = 0
            return false''')

# g26 — the semantic-child filter answering TRUE for whitespace-only text, so
# `<div>\n  <b/>\n</div>` has three children where the reference has one. ★★PREDICTED
# UNGATED, and the prediction is a PROOF rather than a guess: the filter's only
# reader is `semantic_jsx_child_count`, whose only reader compares it against ZERO —
# so the flip can change a verdict for exactly one shape, an element ALL of whose
# children are whitespace-only (`<div>\n</div>`) beside a declared children property.
# Nothing in the corpus carries it. `check_jsx_children` reads
# `jsx_text_is_whitespace_only` directly and is untouched by this row.
mk('g26.py',
   '''        if k = KindJsxText
            return jsx_text_is_whitespace_only(c) = false
        true''',
   '''        if k = KindJsxText
            return true
        true''')

# g27 — getSpreadType's primitive-right arm removed. ★★PREDICTED UNGATED: the RIGHT
# operand at both of this port's call sites is the attributes object this file just
# built, and the only way to hand it a primitive is `{...1}` — which stops one line
# earlier, at `jsx-spread-attribute-value`. "Spreading a primitive adds nothing" is
# transcribed because the arm decides an answer the day isValidSpreadType lands.
mk('g27.py',
   '''        if (right.flags & primitive_right) <> 0
            return left''',
   '''        if false
            return left''')
MK

control "g01 the JSX element arm back to a stop"                 $CHECKER "$PATCHDIR/g01.py"
control "g02 the self-closing arm back to a stop"                $CHECKER "$PATCHDIR/g02.py"
control "g03 the fragment arm back to a stop"                    $CHECKER "$PATCHDIR/g03.py"
control "g04 TS17004 removed"                                    $CHECKER "$PATCHDIR/g04.py"
control "g05 TS7026 removed"                                     $CHECKER "$PATCHDIR/g05.py"
control "g06 the closing tag never resolved"                     $CHECKER "$PATCHDIR/g06.py"
control "g07 the intrinsic-tag memo never read"                  $CHECKER "$PATCHDIR/g07.py"
control "g08 the namespace memo never stored"                    $CHECKER "$PATCHDIR/g08.py"
control "g09 the memo's third state dropped"                     $CHECKER "$PATCHDIR/g09.py"
control "g10 the globals-miss guard back to the identity"        $CHECKER "$PATCHDIR/g10.py"
control "g11 the empty JSX object minted unresolved"             $CHECKER "$PATCHDIR/g11.py"
control "g12 a bare attribute given boolean, not true"           $CHECKER "$PATCHDIR/g12.py"
control "g13 the JsxAttribute arm of the variable worker"        $CHECKER "$PATCHDIR/g13.py"
control "g14 the hyphen disjunct of the intrinsic test"          $CHECKER "$PATCHDIR/g14.py"
control "g15 the namespaced disjunct of the intrinsic test"      $CHECKER "$PATCHDIR/g15.py"
control "g16 TS17001 removed"                                    $CHECKER "$PATCHDIR/g16.py"
control "g17 TS17000 removed"                                    $CHECKER "$PATCHDIR/g17.py"
control "g18 TS18007 removed"                                    $CHECKER "$PATCHDIR/g18.py"
control "g19 TS2609 removed"                                     $CHECKER "$PATCHDIR/g19.py"
control "g20 the JSX fork removed from applicability"            $CHECKER "$PATCHDIR/g20.py"
control "g21 the children term of the argument list"             $CHECKER "$PATCHDIR/g21.py"
control "g22 the JSX parameter-count clamp dropped"              $CHECKER "$PATCHDIR/g22.py"
control "g23 getContextNode's JsxAttributes arm removed"         $CHECKER "$PATCHDIR/g23.py"
control "g24 getJsxType answering null on a miss"                $CHECKER "$PATCHDIR/g24.py"
control "g25 the zero-property container read as missing"        $CHECKER "$PATCHDIR/g25.py"
control "g26 whitespace-only text counted as a child"            $AST "$PATCHDIR/g26.py"
control "g27 the primitive-spread arm removed"                   $CHECKER "$PATCHDIR/g27.py"
