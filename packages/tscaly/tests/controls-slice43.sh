#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice43.sh — the slice-43 control battery, eleven of them.
#
# Slice 43 is `infer U`: bindTypeParameter's OTHER arm, plus the ancestor walk it
# needs (getInferTypeContainer) and the anonymous declaration it falls back to.
#
# ★★★ FOUR GROUPS, AND THE MIDDLE ONE IS THE SLICE.
#
#   c1        what the slice UNLOCKS: the arm at all.
#
#   c2..c5    the CONTAINER, which is the whole content of the arm and is four
#             separate claims rather than one — the table is the CONDITIONAL
#             type's locals and not the current container's (c2); the ancestor
#             must be a conditional's extendsType and not merely a conditional
#             (c3); the walk STARTS at the InferType node (c4); and it CONTINUES
#             past a parent that does not match (c5). Each of the last three is a
#             different way to get the same function almost right, and each has
#             its own fixture — c3/c5 the nested one, c4 the zero-hop one.
#
#   c6..c7    the NULL container, i.e. the arm's second rule: the anonymous
#             declaration, and the name it carries.
#
#   c8..c11   the four arguments the declaring call passes — the excludes that
#             permit a same-name MERGE, the classifiable name the anonymous path
#             does NOT write, the gate that selects the arm, and the null parent.
#
# ★★ c9 IS AN ADDITION AND NOT A REMOVAL, because the claim it measures is an
# ABSENCE: a type parameter IS classifiable, and the anonymous path nevertheless
# leaves the file's classifiable set alone, since that set is written by
# declareSymbolEx. There is nothing to take away, so the control puts the write in
# and measures what moves. The same shape as slice 42's c4 in reverse.
#
# ★★★ c10 WIDENS A GATE RATHER THAN NARROWING IT, which is the direction ctl.sh's
# header warns about, so read its number with that in mind: `if false` on the
# InferType test does not disable the infer path, it sends EVERY type parameter
# down the ordinary one — which is a different wrong answer from c1's, because
# declareSymbolAndAddToSymbolTable routes by the CONTAINER's kind and a conditional
# type is not one of its kinds. The row therefore says *this gate selects the arm*,
# not *this many units have an infer type*; c1 is the row that counts those.
#
# Usage (it patches the source tree and restores it after every control, so
# nothing may edit the tree while it runs — §3.5y):
#
#   packages/tscaly/tests/controls-slice43.sh 2>&1 | tee /tmp/battery43.log
#
# 1 baseline + 11 controls = 12 runs, about 7 minutes on an idle box. ★If it takes
# hours, read §3.5ck before suspecting the battery.

set -u
cd "$(dirname "$0")/../../.."

CTL=packages/tscaly/tests/ctl.sh
B=packages/tscaly/0.1.1/tscaly/binder.scaly

export TSCALY_BASELINE=$(mktemp -t tscaly-baseline)
cleanup() { rm -f "$TSCALY_BASELINE" "$TSCALY_BASELINE.fp"; }
trap cleanup EXIT

echo "################################################################"
if ! "$CTL" --establish-baseline </dev/null; then
  exit 2
fi

run() { echo; echo "################################################################"; "$CTL" "$1"; }

# ── group 1: what the slice unlocks ──────────────────────────────────────────

run "c1 an infer type parameter is bound at all" <<SPEC
FILE $B
<<<OLD
                let c Binder.get_infer_type_container(p)
                if c <> null
                {
                    this.declare_symbol(Binder.get_locals(host, c), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
                    return
                }
                var nd null as pointer[char]
                var nl 0
                this.get_declaration_name(n, &nd, &nl)
                if this.is_unported()
                    return
                this.bind_anonymous_declaration(n, SymbolFlagsTypeParameter, nd, nl)
                return
>>>NEW
                this.record_unported("type-parameter-infer", 0)
                return
SPEC

# ── group 2: the container ───────────────────────────────────────────────────

run "c2 the table is the CONDITIONAL type's locals, not the current container's" <<SPEC
FILE $B
<<<OLD
                    this.declare_symbol(Binder.get_locals(host, c), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
>>>NEW
                    this.declare_symbol(Binder.get_locals(host, container), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
SPEC

run "c3 the ancestor must be a conditional's extendsType, not merely a conditional" <<SPEC
FILE $B
<<<OLD
                    if AstNode.conditional_extends_type_of(parent) = node
                        return parent
>>>NEW
                    return parent
SPEC

run "c4 the walk STARTS at the InferType node (zero hops is a match)" <<SPEC
FILE $B
<<<OLD
        var node n
        while node <> null
        {
            let parent AstNode.parent_node_of(node)
            if parent <> null
            {
                if AstNode.kind_of(parent) = KindConditionalType
>>>NEW
        var node AstNode.parent_node_of(n)
        while node <> null
        {
            let parent AstNode.parent_node_of(node)
            if parent <> null
            {
                if AstNode.kind_of(parent) = KindConditionalType
SPEC

run "c5 the walk CONTINUES past a parent that does not match" <<SPEC
FILE $B
<<<OLD
            set node: parent
>>>NEW
            set node: null as pointer[AstNode]
SPEC

# ── group 3: the null container ──────────────────────────────────────────────

run "c6 a null container takes the ANONYMOUS path, not a table" <<SPEC
FILE $B
<<<OLD
                var nd null as pointer[char]
                var nl 0
                this.get_declaration_name(n, &nd, &nl)
                if this.is_unported()
                    return
                this.bind_anonymous_declaration(n, SymbolFlagsTypeParameter, nd, nl)
                return
>>>NEW
                this.declare_symbol(Binder.get_locals(host, container), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
                return
SPEC

run "c7 the anonymous symbol's name is getDeclarationName's, not an internal one" <<SPEC
FILE $B
<<<OLD
                this.get_declaration_name(n, &nd, &nl)
                if this.is_unported()
                    return
                this.bind_anonymous_declaration(n, SymbolFlagsTypeParameter, nd, nl)
>>>NEW
                set nl: Binder.internal_name(host, "type", &nd)
                this.bind_anonymous_declaration(n, SymbolFlagsTypeParameter, nd, nl)
SPEC

# ── group 4: the four arguments ──────────────────────────────────────────────

run "c8 the excludes permit a same-name MERGE (TypeParameter is not excluded)" <<SPEC
FILE $B
<<<OLD
                    this.declare_symbol(Binder.get_locals(host, c), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
>>>NEW
                    this.declare_symbol(Binder.get_locals(host, c), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsType)
SPEC

run "c9 the anonymous path writes NO classifiable name (added: it does)" <<SPEC
FILE $B
<<<OLD
                this.bind_anonymous_declaration(n, SymbolFlagsTypeParameter, nd, nl)
                return
>>>NEW
                SymbolTable.set_entry(host, classifiable_names, nd, nl, null as pointer[Symbol])
                this.bind_anonymous_declaration(n, SymbolFlagsTypeParameter, nd, nl)
                return
SPEC

run "c10 the InferType parent is what selects the arm (widened: every type parameter takes the ordinary one)" <<SPEC
FILE $B
<<<OLD
            if AstNode.kind_of(p) = KindInferType
>>>NEW
            if false
SPEC

run "c11 the declared symbol has NO parent" <<SPEC
FILE $B
<<<OLD
                    this.declare_symbol(Binder.get_locals(host, c), null as pointer[Symbol], n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
>>>NEW
                    this.declare_symbol(Binder.get_locals(host, c), AstNode.symbol_of(container), n, SymbolFlagsTypeParameter, SymbolFlagsTypeParameterExcludes)
SPEC
