#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice22.sh — the slice-22 control battery, forty-five of them.
#
# ★★★ WHY THIS FILE EXISTS AT ALL, when no earlier slice has one. `ctl.sh` is
# committed and the RESULT tables were kept — but the SPECS were
# thrown away after every battery through slice 21, so a row of those tables
# names a claim and a number and nothing that can reproduce either. That is the
# shape ctl.sh's own header argues against ("a harness whose rules live only in
# prose about it is a harness that gets re-broken"), applied one level up: the
# table is prose about a measurement whose instrument no longer exists.
#
# Each entry below breaks exactly ONE claim of the JSDoc reparser and measures
# what turns red. A row of the result table and a
# `run` here carry the same label, deliberately, so the two can be diffed.
#
# ★ THE NUMBERS IN THAT TABLE ARE A MEASUREMENT OF ONE TREE ON ONE DAY. Re-run
# this file after any change to the reparser and expect them to MOVE — a fixture
# added later raises a red count, a defect fixed later can lower one. What must
# not change without an argument is a row's VERDICT: a RED row going UNGATED
# means the claim has lost its witness.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice22.sh 2>&1 | tee /tmp/battery.log
#
# To run ONE control, copy its spec into ctl.sh directly:
#
#   packages/tscaly/tests/ctl.sh "label" <<'SPEC'
#   ... the spec ...
#   SPEC
#
# ★★★ THE BATTERY IS 47 RUNS, NOT 135, AND THE ARITHMETIC IS THE WHOLE OF IT.
# Each control used to measure three: its own baseline, the patched tree, and the
# baseline again after restoring. But the "after" of control N and the "before" of
# control N+1 are the SAME TREE by construction — ctl.sh restores the one file it
# patched and touches nothing else — so of those 90 baseline runs, 88 were
# measuring a tree that had already been measured, most of them twice in a row.
# What replaces them is ONE baseline at the top, a
# FINGERPRINT over every input that each control verifies before trusting it and
# again after restoring, and ONE clean run at the bottom that has to reproduce the
# baseline report byte for byte. 1 + 45 + 1.
#
# ★★ Nothing was dropped from the CHECKING to buy that — the fingerprint sees any
# byte of any input, where the four-counter comparison it replaces could not see a
# change that does not move a counter (§3.5y's own hole). ctl.sh's header has the
# argument.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
RUN=packages/tscaly/tests/run.sh
P=packages/tscaly/0.1.0/tscaly/parser.scaly
A=packages/tscaly/0.1.0/tscaly/ast.scaly

# The shared baseline lives for the length of this battery and no longer. A cache
# that outlives the process it was measured in is the stale baseline slice 7
# nearly lost three gates to.
export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
BATTERY_START=$(python3 -c 'import time; print(time.time())')
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }
run "c1 the reparser never runs at all" <<SPEC
FILE $P
<<<OLD
            if this.is_java_script()
                this.reparse_tags(n, jsdoc)
>>>NEW
            if false
                this.reparse_tags(n, jsdoc)
SPEC

run "c2 the reparse list is never flushed into the enclosing list" <<SPEC
FILE $P
<<<OLD
                        if outwards
                            outer_reparse_list.add(e)
                        else
                            list.add(e)
>>>NEW
                        if outwards
                            outer_reparse_list.add(e)
SPEC

run "c3 a declaration is never propagated OUTWARDS to a list that can hold it" <<SPEC
FILE $P
<<<OLD
                            if (ctx <> PCSourceElements) and (ctx <> PCBlockStatements)
                                set outwards: true
>>>NEW
                            if false
                                set outwards: true
SPEC

run "c4 the statement index does not account for the inserted declarations" <<SPEC
FILE $P
<<<OLD
        set i: i + (reparse_list.get_length() as int)
>>>NEW
        set i: i + 0
SPEC

run "c5 @typedef and @callback produce no declaration" <<SPEC
FILE $P
<<<OLD
            let type_expression AstNode.jsdoc_type_expression_of(tag)
            if type_expression = null
                return
>>>NEW
            let type_expression AstNode.jsdoc_type_expression_of(tag)
            if true
                return
SPEC

run "c6 @import produces no import declaration" <<SPEC
FILE $P
<<<OLD
            let clause AstNode.jsdoc_import_clause_of(tag)
            if clause = null
                return
>>>NEW
            let clause AstNode.jsdoc_import_clause_of(tag)
            if true
                return
SPEC

run "c7 @overload produces no overload signature" <<SPEC
FILE $P
<<<OLD
            if ok = false
                return
            if (parsing_contexts & (1 << PCObjectLiteralMembers)) <> 0
                return
>>>NEW
            if ok = false
                return
            if true
                return
SPEC

run "c8 @overload fires inside an object literal too" <<SPEC
FILE $P
<<<OLD
            if (parsing_contexts & (1 << PCObjectLiteralMembers)) <> 0
                return
            let te AstNode.jsdoc_type_expression_of(tag)
>>>NEW
            if false
                return
            let te AstNode.jsdoc_type_expression_of(tag)
SPEC

run "c9 @type does not annotate a variable STATEMENT's first untyped declaration" <<SPEC
FILE $P
<<<OLD
                if AstNode.type_of(d) = null
                {
                    AstNode.set_type(d, this.add_deep_clone_reparse(inner))
                    return true
                }
>>>NEW
                if AstNode.type_of(d) = null
                {
                    return false
                }
SPEC

run "c10 @type does not annotate the six DIRECT hosts" <<SPEC
FILE $P
<<<OLD
        if direct
        {
            if AstNode.type_of(parent) <> null
                return false
            AstNode.set_type(parent, this.add_deep_clone_reparse(inner))
            return true
        }
>>>NEW
        if direct
        {
            return false
        }
SPEC

run "c11 @type on a PARAMETER goes through the plain clone, not the type-literal reparse" <<SPEC
FILE $P
<<<OLD
            AstNode.set_type(parent, this.reparse_jsdoc_type_literal(inner))
            return true
        }

        if pk = KindExpressionStatement
>>>NEW
            AstNode.set_type(parent, this.add_deep_clone_reparse(inner))
            return true
        }

        if pk = KindExpressionStatement
SPEC

run "c12 @type does not annotate an assignment-declaration expression statement" <<SPEC
FILE $P
<<<OLD
            if is_assignment_declaration(bin) = false
                return false
            AstNode.set_type(bin, this.add_deep_clone_reparse(inner))
>>>NEW
            if true
                return false
            AstNode.set_type(bin, this.add_deep_clone_reparse(inner))
SPEC

run "c13 @type does not wrap a returned or parenthesized expression in a cast" <<SPEC
FILE $P
<<<OLD
            AstNode.set_expression(parent, this.make_new_cast(this.add_deep_clone_reparse(inner), e, true))
            return true
>>>NEW
            return false
SPEC

run "c14 @type never becomes a function's FULL SIGNATURE" <<SPEC
FILE $P
<<<OLD
            AstNode.set_full_signature(fun, this.add_deep_clone_reparse(AstNode.jsdoc_type_expression_inner_of(te)))
>>>NEW
            AstNode.set_full_signature(fun, null)
SPEC

run "c15 @satisfies is not applied at all" <<SPEC
FILE $P
<<<OLD
        if tk = KindJSDocSatisfiesTag
        {
            this.reparse_satisfies_tag(tag, parent)
            return
        }
>>>NEW
        if tk = KindJSDocSatisfiesTag
        {
            return
        }
SPEC

run "c16 @template gives a function no type parameters" <<SPEC
FILE $P
<<<OLD
                    if AstNode.full_signature_of(fun) = null
                        AstNode.set_type_parameters(fun, this.gather_type_parameters(jsdoc, false))
>>>NEW
                    if AstNode.full_signature_of(fun) = null
                        AstNode.set_type_parameters(fun, null)
SPEC

run "c17 @template gives a CLASS no type parameters" <<SPEC
FILE $P
<<<OLD
                if AstNode.type_parameters_of(parent) = null
                    AstNode.set_type_parameters(parent, this.gather_type_parameters(jsdoc, false))
>>>NEW
                if AstNode.type_parameters_of(parent) = null
                    AstNode.set_type_parameters(parent, null)
SPEC

run "c18 a @typedef in the comment does NOT cancel the @template gather" <<SPEC
FILE $P
<<<OLD
            if typedef_or_callback = false
            {
                if (tag.kind = KindJSDocTypedefTag) or (tag.kind = KindJSDocCallbackTag)
                    return null
            }
>>>NEW
            if false
            {
                if (tag.kind = KindJSDocTypedefTag) or (tag.kind = KindJSDocCallbackTag)
                    return null
            }
SPEC

run "c19 the first @template's CONSTRAINT is not applied to its first parameter" <<SPEC
FILE $P
<<<OLD
                    if (constraint <> null) and first_type_parameter
>>>NEW
                    if false
SPEC

run "c20 @param does not annotate the parameter it names" <<SPEC
FILE $P
<<<OLD
            if AstNode.type_of(param) = null
            {
                if te <> null
                    AstNode.set_type(param, this.reparse_jsdoc_type_literal(AstNode.jsdoc_type_expression_inner_of(te)))
            }
>>>NEW
            if AstNode.type_of(param) = null
            {
                if te <> null
                    AstNode.set_type(param, null)
            }
SPEC

run "c21 findMatchingParameter matches by NAME only, never by index" <<SPEC
FILE $P
<<<OLD
                        if index = tag_index
                        {
                            if AstNode.identifier_text_length_of(tag_name) = 0
                                return parameter
                        }
>>>NEW
                        if false
                        {
                            if AstNode.identifier_text_length_of(tag_name) = 0
                                return parameter
                        }
SPEC

run "c22 an optional tag produces no QUESTION token" <<SPEC
FILE $P
<<<OLD
        var optional AstNode.jsdoc_param_is_bracketed(tag)
>>>NEW
        var optional false
SPEC

run "c23 @this adds no this-parameter" <<SPEC
FILE $P
<<<OLD
            if has_this
                return
            let bytes this.copy_bytes_to_page("this", 4)
>>>NEW
            if true
                return
            let bytes this.copy_bytes_to_page("this", 4)
SPEC

run "c24 @returns does not become the return type" <<SPEC
FILE $P
<<<OLD
            AstNode.set_type(fun, this.add_deep_clone_reparse(AstNode.jsdoc_type_expression_inner_of(te)))
            return
        }

        if is_jsdoc_modifier_tag(tk)
>>>NEW
            AstNode.set_type(fun, null)
            return
        }

        if is_jsdoc_modifier_tag(tk)
SPEC

run "c25 the five modifier tags add no modifier" <<SPEC
FILE $P
<<<OLD
        nodes.add(modifier)
        AstNode.set_modifiers(parent, nodes)
>>>NEW
        AstNode.set_modifiers(parent, nodes)
SPEC

run "c26 a modifier tag fires inside an object literal too" <<SPEC
FILE $P
<<<OLD
            if (parsing_contexts & (1 << PCObjectLiteralMembers)) <> 0
                return
        }
        else
>>>NEW
            if false
                return
        }
        else
SPEC

run "c27 @implements adds no heritage clause" <<SPEC
FILE $P
<<<OLD
        if tk = KindJSDocImplementsTag
        {
            this.reparse_implements_tag(tag, parent)
            return
        }
>>>NEW
        if tk = KindJSDocImplementsTag
        {
            return
        }
SPEC

run "c28 @augments fills in no type arguments" <<SPEC
FILE $P
<<<OLD
        if tk = KindJSDocAugmentsTag
            this.reparse_augments_tag(tag, parent)
>>>NEW
        if false
            this.reparse_augments_tag(tag, parent)
SPEC

run "c29 a dotted @typedef name is not wrapped in namespaces" <<SPEC
FILE $P
<<<OLD
        if full_name.kind <> KindModuleDeclaration
            return statement
        let wrapped this.wrap_in_jsdoc_namespace(AstNode.body_of(full_name), statement, true)
>>>NEW
        if full_name.kind <> KindUnknown
            return statement
        let wrapped this.wrap_in_jsdoc_namespace(AstNode.body_of(full_name), statement, true)
SPEC

run "c30 a nested JSDoc namespace gets no export modifier" <<SPEC
FILE $P
<<<OLD
        var modifiers null as pointer[Array[pointer[AstNode]]]
        if nested
            set modifiers: this.create_export_modifier(full_name)
>>>NEW
        var modifiers null as pointer[Array[pointer[AstNode]]]
        if false
            set modifiers: this.create_export_modifier(full_name)
SPEC

run "c31 a variadic @param produces no dot-dot-dot token" <<SPEC
FILE $P
<<<OLD
                    set dot_dot_dot: this.new_node(KindDotDotDotToken, NodeData.Token(TokenData()))
                    this.finish_reparsed_node(dot_dot_dot, param)
>>>NEW
                    set dot_dot_dot: null
SPEC

run "c32 a sub-property @param x.y becomes a parameter of its own" <<SPEC
FILE $P
<<<OLD
        let raw_name AstNode.name_of(param)
        if raw_name <> null
        {
            if raw_name.kind = KindQualifiedName
                return null
        }
>>>NEW
        let raw_name AstNode.name_of(param)
        if raw_name <> null
        {
            if raw_name.kind = KindUnknown
                return null
        }
SPEC

run "c33 a @param name that is not an identifier is not sanitized" <<SPEC
FILE $P
<<<OLD
                if this.is_valid_identifier_text(name) = false
                    set name: this.sanitize_parameter_name(name, index)
                else
                    set name: this.add_deep_clone_reparse(name)
>>>NEW
                set name: this.add_deep_clone_reparse(name)
SPEC

run "c34 a @property name that is not an identifier stays an identifier" <<SPEC
FILE $P
<<<OLD
                            let s this.new_node(KindStringLiteral, NodeData.StringLiteral(LiteralData(TokenFlagsNone)))
                            set name: this.add_transformed_reparse(s, name)
>>>NEW
                            set name: this.add_deep_clone_reparse(name)
SPEC

run "c35 an Object[] typedef does not become an ARRAY of the type literal" <<SPEC
FILE $P
<<<OLD
        if is_array
        {
            this.finish_reparsed_node(r, t)
            set r: this.new_node(KindArrayType, NodeData.ArrayType(WrappedTypeData(r)))
        }
>>>NEW
        if false
        {
            this.finish_reparsed_node(r, t)
            set r: this.new_node(KindArrayType, NodeData.ArrayType(WrappedTypeData(r)))
        }
SPEC

run "c36 a tag's comment does not become the synthesized node's JSDoc" <<SPEC
FILE $P
<<<OLD
        let comment AstNode.jsdoc_tag_comment_of(tag)
        if comment = null
            return
>>>NEW
        let comment AstNode.jsdoc_tag_comment_of(tag)
        if true
            return
SPEC

run "c37 the JavaScript accessor re-derives instead of reading the cache" <<SPEC
FILE $P
<<<OLD
        if this.is_java_script()
            return this.lookup_jsdoc_info(n)
>>>NEW
        if false
            return this.lookup_jsdoc_info(n)
SPEC

run "c38 a clone is an ALIAS — the Reparsed bit lands on the JSDoc node itself" <<SPEC
FILE $P
<<<OLD
        let c AstNode.alloc(host)
        set *c: *n
        set c.flags: c.flags | NodeFlagsReparsed
        c
>>>NEW
        set n.flags: n.flags | NodeFlagsReparsed
        n
SPEC

run "c39 a reparsed node keeps the flags it was built with instead of taking the context" <<SPEC
FILE $P
<<<OLD
        set n.flags: context_flags | NodeFlagsReparsed
        set n.pos: location.pos
>>>NEW
        set n.flags: n.flags | NodeFlagsReparsed
        set n.pos: location.pos
SPEC

run "c40 the unfinished any-keyword placeholder takes 0,0 rather than the undefined range" <<SPEC
FILE $P
<<<OLD
                        set any_kw.pos: 0 - 1
                        set any_kw.end: 0 - 1
>>>NEW
                        set any_kw.pos: 0
                        set any_kw.end: 0
SPEC

run "c41 checkNonIdentifierName is applied to the @callback name as well" <<SPEC
FILE $P
<<<OLD
            var raw_alias_name get_innermost_name_of_jsdoc_namespace(full_name)
            if tk = KindJSDocTypedefTag
                set raw_alias_name: this.check_non_identifier_name(raw_alias_name)
>>>NEW
            var raw_alias_name get_innermost_name_of_jsdoc_namespace(full_name)
            if true
                set raw_alias_name: this.check_non_identifier_name(raw_alias_name)
SPEC

run "c42 an assignment expression does not have to have a valid TARGET" <<SPEC
FILE $P
<<<OLD
        let left AstNode.binary_left_of(n)
        if left = null
            return false
        is_left_hand_side_expression_kind(left.kind)
>>>NEW
        true
SPEC

run "c43 IsFunctionLikeKind is narrowed to the seven DECLARATION kinds" <<SPEC
FILE $P
<<<OLD
        if k = KindMethodSignature
            return true
        if k = KindCallSignature
            return true
        if k = KindConstructSignature
            return true
        if k = KindIndexSignature
            return true
        if k = KindFunctionType
            return true
        if k = KindConstructorType
            return true
        k = KindJSDocSignature
>>>NEW
        false
SPEC

run "c44 a synthesized identifier takes 0,0 instead of the undefined range" <<SPEC
FILE $P
<<<OLD
        let n this.new_node(KindIdentifier, NodeData.Identifier(IdentifierData(bytes, len)))
        set n.pos: 0 - 1
        set n.end: 0 - 1
        n
>>>NEW
        this.new_node(KindIdentifier, NodeData.Identifier(IdentifierData(bytes, len)))
SPEC

run "c45 the signature members get no full_signature slot at all" <<SPEC
FILE $A
<<<OLD
            when ms: MethodSignature
                return ms.full_signature
            when cs: CallSignature
                return cs.full_signature
            when ks: ConstructSignature
                return ks.full_signature
            when ix: IndexSignatureDeclaration
                return ix.full_signature
>>>NEW
SPEC

# ── the 47th run: the tree must come back to where the battery found it ──────
#
# ★★★ THIS IS THE ONE CHECK THAT CANNOT BE REPLACED BY A HASH, and it is why the
# battery ends with a run rather than with the last control. Each control verifies
# its own restore by fingerprint, so the INPUTS are provably unchanged — but a
# fingerprint says nothing about whether those inputs still produce the report the
# battery was measured against. A build that has drifted, a submodule that moved,
# an oracle stamp that went stale: all of them keep the fingerprint and change the
# answer. Reproducing the baseline report BYTE FOR BYTE is the statement the
# forty-five numbers above rest on.
echo
echo "################################################################"
echo "the 47th run: reproducing the baseline from the restored tree ..."
FINAL=$(mktemp -t tscaly-final)
"$RUN" > "$FINAL" 2>&1 </dev/null
FINAL_RC=$?
if [ $FINAL_RC -ne 0 ]; then
  printf '\033[31m%s\033[0m\n' "the final run is not green (rc $FINAL_RC) — the battery left the tree broken."
  tail -30 "$FINAL"
  rm -f "$FINAL"
  exit 2
fi
if diff -q "$TSCALY_BASELINE" "$FINAL" > /dev/null 2>&1; then
  printf '\033[32m%s\033[0m\n' "BATTERY VERIFIED: the final report is byte-identical to the baseline."
  echo "  So every control above was measured against this tree, and the tree is"
  echo "  the one the battery started from."
else
  printf '\033[31m%s\033[0m\n' "THE FINAL REPORT DIFFERS FROM THE BASELINE — every number above is suspect."
  echo "  The shared baseline no longer describes this tree, which means something"
  echo "  moved during the battery that the per-control fingerprints did not see."
  diff "$TSCALY_BASELINE" "$FINAL" | head -40
  rm -f "$FINAL"
  exit 1
fi
rm -f "$FINAL"

python3 -c 'import sys,time; d=time.time()-float(sys.argv[1]); print("battery wall time: %d min %d s (%d runs of the yardsticks)" % (d//60, d%60, 47))' "$BATTERY_START"
