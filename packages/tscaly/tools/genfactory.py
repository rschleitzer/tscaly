#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# genfactory.py — the port of internal/ast/ast_generated.go's NODE FACTORY, generated.
#
# ★★★ WHY GENERATED (slice 231). The reference file is 10 000 generated lines: per node
# kind a constructor, an updater (same children → the same node, else a new one carrying
# the original's flags and location), a child visitor for the transformers and a clone.
# A hand transcription of 190 such quadruples is a transcription-slip machine, and a
# slip here is a wrong CHILD ORDER — visible only as a wrong emit several transforms
# away. So the port is derived from the reference's own text by this script, the way
# §3.23 derives every reference table, against the port's own node records: each Go
# constructor parameter is mapped onto the port's NodeData arm and record field, by
# name (snake case, `Type` → `type_node`) plus the override table below where the port
# named a field differently or shares a record between kinds.
#
# What it emits (tscaly/factory.scaly):
#   NodeFactory — new_node (allocation + the emit context's OnCreate), update_node and
#                 clone_node (the reference's updateNode/cloneNode with the hooks),
#                 new_<kind>(…) and update_<kind>(node, …) per constructor, clone(node);
#   NodeVisitor — visit_each_child(node), the per-kind dispatch of VisitEachChild.
# The visitor's own methods (visit_node, visit_nodes, …, visitor.go) are hand-written in
# factory.scaly's companion block, appended by this script from FACTORY_TAIL.
#
# Usage:  python3 packages/tscaly/tools/genfactory.py [--report]   (from the repo root)
import re, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
GEN = os.path.join(ROOT, 'packages/tscaly/_submodules/typescript-go/internal/ast/ast_generated.go')
AST = os.path.join(ROOT, 'packages/tscaly/0.1.0/tscaly/ast.scaly')
OUT = os.path.join(ROOT, 'packages/tscaly/0.1.0/tscaly/factory.scaly')

RESERVED = {'label': 'label_name', 'init': 'init_value', 'loop': 'loop_value', 'shared': 'shared_value', 'operator': 'operator_kind', 'namespace': 'namespace_name'}
def snake(n):
    x = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', n)
    x = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', x).lower()
    return RESERVED.get(x, x)

# ── the port's records and arms ──
ast_src = open(AST, encoding='utf-8').read()
records = {}
for m in re.finditer(r'\ndefine (\w+Data)\s*\n\((.*?)\n\)', ast_src, re.S):
    records[m.group(1)] = re.findall(r'^\s{4}([a-z_0-9]+):\s*(.+?)\s*$', m.group(2), re.M)
for m in re.finditer(r'\ndefine (\w+Data) \((.*?)\)\n', ast_src):
    body = m.group(2).strip()
    records[m.group(1)] = [(f.strip(), t.strip()) for f, t in re.findall(r'([a-z_0-9]+):\s*([^\s]+(?:\[[^\]]*\])?\??)', body)] if body else []
union = re.search(r'\ndefine NodeData union\n\((.*?)\n\)', ast_src, re.S).group(1)
arms = dict(re.findall(r'^\s{4}(\w+): (\w+Data)', union, re.M))

# ── overrides: (GoStruct, GoField) → port field; '' drops the value ──
OVERRIDE = {
    ('LabeledStatement', 'Label'): 'label_name', ('BreakStatement', 'Label'): 'label_name',
    ('ContinueStatement', 'Label'): 'label_name',
    ('TypeOperatorNode', 'Type'): 'inner', ('TypeOperatorNode', 'Operator'): 'operator_kind',
    ('PrefixUnaryExpression', 'Operator'): 'operator_kind',
    ('PostfixUnaryExpression', 'Operator'): 'operator_kind',
    ('TemplateLiteralTypeSpan', 'Type'): 'expression',
    ('JsxNamespacedName', 'Namespace'): 'namespace_name',
    ('JSDocTypeLiteral', 'JSDocPropertyTags'): 'property_tags',
    ('MissingDeclaration', 'modifiers'): 'elements',
    ('NoSubstitutionTemplateLiteral', 'TemplateFlags'): 'token_flags',
    ('TemplateHead', 'TemplateFlags'): 'token_flags', ('TemplateMiddle', 'TemplateFlags'): 'token_flags',
    ('TemplateTail', 'TemplateFlags'): 'token_flags',
    ('TemplateHead', 'RawText'): '', ('TemplateMiddle', 'RawText'): '', ('TemplateTail', 'RawText'): '',
    ('JSDocText', 'Text'): '', ('JSDocLink', 'Text'): '', ('JSDocLinkPlain', 'Text'): '', ('JSDocLinkCode', 'Text'): '',
    ('TupleTypeNode', 'Elements'): 'types', ('JSDocText', 'text'): '', ('MissingDeclaration', 'Modifiers'): 'elements',
}
# a Go struct whose kind is a parameter: the port arms it may become
KIND_ARMS = {
    'ForInOrOfStatement': ['ForInStatement', 'ForOfStatement'],
    'CaseOrDefaultClause': ['CaseClause', 'DefaultClause'],
    'BindingPattern': ['ObjectBindingPattern', 'ArrayBindingPattern'],
    'JSDocParameterOrPropertyTag': ['JSDocParameterOrPropertyTag'],
    'Token': ['Token'], 'KeywordExpression': ['Token'], 'KeywordTypeNode': ['Token'],
}
# Go struct → port arm where the kind constant's name is not the arm's
ARM_OF = {
    'ConstructorDeclaration': ['ConstructorDeclaration'], 'GetAccessorDeclaration': ['GetAccessorDeclaration'],
    'SetAccessorDeclaration': ['SetAccessorDeclaration'], 'IndexSignatureDeclaration': ['IndexSignatureDeclaration'],
    'DebuggerStatement': ['Token'], 'SemicolonClassElement': ['Token'], 'OmittedExpression': ['Token'],
    'ThisTypeNode': ['Token'], 'JsxOpeningFragment': ['Token'], 'JsxClosingFragment': ['Token'],
    'NotEmittedStatement': ['Token'], 'NotEmittedTypeElement': ['Token'],
}
# the checker's own synthetic expression is not a factory product here
SKIP = {'SyntheticExpression'}

def go_type_to_scaly(t):
    if t in ('bool',): return 'bool'
    if t in ('string',): return 'Slice[char]'
    if t == '[]string': return 'Slice[char]'
    if t.endswith('List') and t.startswith('*'): return 'ref[Array[ref[AstNode]?]]?'
    if t.startswith('*'): return 'ref[AstNode]?'
    if t == '[]*Node': return 'ref[Array[ref[AstNode]?]]?'
    if t == 'any': return 'ref[AstNode]?'
    return 'int'   # Kind, NodeFlags, TokenFlags, …

def default_of(t):
    if t == 'bool': return 'false'
    if t == 'int': return '0'
    if t == 'Slice[char]': return 'empty_text'
    return 'null'

gen = open(GEN, encoding='utf-8').read()
news = {}
for m in re.finditer(r'\nfunc \(f \*NodeFactory\) New(\w+)\((.*?)\) \*Node \{\n(.*?)\n\}', gen, re.S):
    name, params, body = m.group(1), m.group(2), m.group(3)
    plist = []
    for p in params.split(','):
        p = p.strip()
        if not p: continue
        pn, pt = p.split(' ', 1)
        plist.append((pn.strip(), pt.strip()))
    assigns = re.findall(r'data\.(\w+) = (\w+)', body)
    km = re.search(r'f\.newNode\((\w+), data\)', body)
    flags = None
    fm = re.search(r'node\.Flags (\|?=) (.+)', body)
    if fm: flags = (fm.group(1), fm.group(2).strip())
    news[name] = dict(params=plist, assigns=assigns, kind=km.group(1), flags=flags)
updates = {}
for m in re.finditer(r'\nfunc \(f \*NodeFactory\) Update(\w+)\(node \*(\w+), (.*?)\) \*Node \{\n(.*?)\n\}', gen, re.S):
    updates[m.group(1)] = m.group(4)
visits = {}
for m in re.finditer(r'\nfunc \(node \*(\w+)\) VisitEachChild\(v \*NodeVisitor\) \*Node \{\n\treturn v\.Factory\.Update(\w+)\(node, (.*?)\)\n\}', gen, re.S):
    visits[m.group(1)] = (m.group(2), m.group(3))
clones = {}
for m in re.finditer(r'\nfunc \(node \*(\w+)\) Clone\(f NodeFactoryCoercible\) \*Node \{\n\treturn cloneNode\(f\.AsNodeFactory\(\)\.New(\w+)\((.*?)\), node\.AsNode\(\)', gen, re.S):
    clones[m.group(1)] = (m.group(2), m.group(3))

report = '--report' in sys.argv
problems = []

def arms_for(name, info):
    if name in KIND_ARMS: return KIND_ARMS[name]
    if name in ARM_OF: return ARM_OF[name]
    k = info['kind']
    if k.startswith('Kind'):
        return [k[4:]]
    return [name]

def map_field(name, gofield, record):
    key = (name, gofield)
    if key in OVERRIDE: return OVERRIDE[key]
    fields = [f for f, _ in records.get(record, [])]
    sf = snake(gofield)
    if sf == 'type': sf = 'type_node'
    if sf in fields: return sf
    if record == 'WrappedTypeData': return 'inner'
    if record == 'ElementListData' and gofield in ('Elements', 'Properties', 'Clauses', 'Children', 'Attributes', 'Statements', 'Declarations'): return 'elements'
    if record == 'JSDocOneSlotTagData' and gofield in ('TypeExpression', 'NameExpression', 'ClassName'): return 'node'
    return None

FACTORY_TAIL = """
    ; ── visitor.go, hand-written ─────────────────────────────────────────────

    ; The `Visit` callback (§3.18: the tag is the func value).
    procedure visit(this, node: ref[AstNode]) returns ref[AstNode]?
    {
        if visit_tag = VisitTagDeepClone
            return this.deep_clone_visit(node)
        if visit_tag = VisitTagTransformer
            return (transformer as ref[Transformer]).visit(node)
        node
    }

    ; VisitNode: the callback, and a one-element SyntaxList unwrapped.
    procedure visit_node(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if node = null
            return null
        if visit_tag = VisitTagNone
            return node
        var visited this.visit(node as ref[AstNode])
        if visited <> null
        {
            let v visited as ref[AstNode]
            if v.kind = KindSyntaxList
            {
                let children this.syntax_list_children(v)
                if (children.get_length() as int) <> 1
                    return null
                set visited: children[0 as size_t]
            }
        }
        visited
    }

    function syntax_list_children(this, n: ref[AstNode]) returns ref[Array[ref[AstNode]?]]
    {
        choose n.data
            when sl: SyntaxList
                return sl.elements
        &Array[ref[AstNode]?]^host()
    }

    ; VisitEmbeddedStatement: the callback, lifted to a block when it answers several.
    procedure visit_embedded_statement(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if node = null
            return null
        if visit_tag = VisitTagNone
            return node
        let visited this.visit(node as ref[AstNode])
        if visited = null
            return null
        this.lift_to_block(visited)
    }

    ; VisitNodes: a rebuilt list keeps the original's extent.
    procedure visit_nodes(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
    {
        if nodes = null
            return nodes
        if visit_tag = VisitTagNone
            return nodes
        var changed false
        let result this.visit_slice(nodes as ref[Array[ref[AstNode]?]], &changed)
        if changed
            return factory.new_node_list_like(result, nodes)
        nodes
    }

    procedure visit_modifiers(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
        this.visit_nodes(nodes)

    ; VisitSlice: the first element the callback changes or drops starts a copy;
    ; a SyntaxList answer splices its children in.
    procedure visit_slice(this, nodes: ref[Array[ref[AstNode]?]], changed: ref[bool]) returns ref[Array[ref[AstNode]?]]
    {
        set changed: false
        let n nodes.get_length() as int
        var i 0
        while i < n
        {
            let node nodes[i as size_t]
            var visited: ref[AstNode]? null
            if node <> null
                set visited: this.visit(node as ref[AstNode])
            var same false
            if visited <> null
            {
                if visited = node
                    set same: true
            }
            if same = false
            {
                let updated &Array[ref[AstNode]?]^host()
                var k 0
                while k < i
                {
                    updated.add(nodes[k as size_t])
                    set k: k + 1
                }
                while true
                {
                    if visited <> null
                    {
                        let v visited as ref[AstNode]
                        if v.kind = KindSyntaxList
                        {
                            let children this.syntax_list_children(v)
                            var c 0
                            while c < (children.get_length() as int)
                            {
                                updated.add(children[c as size_t])
                                set c: c + 1
                            }
                        }
                        else
                            updated.add(visited)
                    }
                    set i: i + 1
                    if i >= n
                        break
                    let next nodes[i as size_t]
                    set visited: null
                    if next <> null
                        set visited: this.visit(next as ref[AstNode])
                }
                set changed: true
                return updated
            }
            set i: i + 1
        }
        nodes
    }

    ; liftToBlock: several statements become one multi-line block.
    procedure lift_to_block(this, node: ref[AstNode]) returns ref[AstNode]
    {
        if node.kind <> KindSyntaxList
            return node
        let children this.syntax_list_children(node)
        if (children.get_length() as int) = 1
        {
            let only children[0 as size_t]
            if only <> null
                return only as ref[AstNode]
        }
        factory.new_block(children, true)
    }

    ; ── the hook-aware forms VisitEachChild calls (visitor.go's lowercase ones) ──

    procedure visit_node_h(this, node: ref[AstNode]?) returns ref[AstNode]?
        this.visit_node(node)

    procedure visit_embedded_statement_h(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if hooks_tag = HooksTagEmitContext
            return (context as ref[EmitContext]).visit_embedded_statement(node, this)
        this.visit_embedded_statement(node)
    }

    procedure visit_iteration_body_h(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if hooks_tag = HooksTagEmitContext
            return (context as ref[EmitContext]).visit_iteration_body(node, this)
        this.visit_embedded_statement_h(node)
    }

    procedure visit_function_body_h(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if hooks_tag = HooksTagEmitContext
            return (context as ref[EmitContext]).visit_function_body(node, this)
        this.visit_node_h(node)
    }

    procedure visit_token_h(this, node: ref[AstNode]?) returns ref[AstNode]?
        this.visit_node(node)

    procedure visit_nodes_h(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
    {
        if hooks_tag = HooksTagDeepClone
            return this.deep_clone_visit_nodes(nodes)
        this.visit_nodes(nodes)
    }

    procedure visit_modifiers_h(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
    {
        if hooks_tag = HooksTagDeepClone
            return this.deep_clone_visit_nodes(nodes)
        this.visit_modifiers(nodes)
    }

    procedure visit_parameters_h(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
    {
        if hooks_tag = HooksTagEmitContext
            return (context as ref[EmitContext]).visit_parameters(nodes, this)
        this.visit_nodes_h(nodes)
    }

    procedure visit_top_level_statements_h(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
    {
        if hooks_tag = HooksTagEmitContext
            return (context as ref[EmitContext]).visit_variable_environment(nodes, this)
        this.visit_nodes_h(nodes)
    }

    ; ── deepclone.go ─────────────────────────────────────────────────────────

    ; The deep-clone callback: a node whose children changed is the rebuilt
    ; one; a leaf is cloned outright, and the clones cascade up through the
    ; updaters. A synthetic location is (-1, -1).
    procedure deep_clone_visit(this, node: ref[AstNode]) returns ref[AstNode]?
    {
        let visited this.visit_each_child(node)
        if visited <> null
        {
            if visited <> node
            {
                if synthetic_location
                {
                    let vn visited as ref[AstNode]
                    set vn.pos: 0 - 1
                    set vn.end: 0 - 1
                }
                return visited
            }
        }
        let c factory.clone(node)
        if synthetic_location
        {
            set c.pos: 0 - 1
            set c.end: 0 - 1
        }
        c
    }

    ; The deep clone's VisitNodes hook: an unchanged list is CLONED (a fresh
    ; Array over the same elements, same extent); with synthetic locations the
    ; list has no extent and a trailing comma is kept as the last element's
    ; (-2, -2) location, exactly the reference's marker.
    procedure deep_clone_visit_nodes(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
    {
        if nodes = null
            return null
        let list nodes as ref[Array[ref[AstNode]?]]
        let visited this.visit_nodes(nodes)
        var new_list: ref[Array[ref[AstNode]?]]? visited
        if visited = nodes
        {
            let copy &Array[ref[AstNode]?]^host()
            var i 0
            while i < (list.get_length() as int)
            {
                copy.add(list[i as size_t])
                set i: i + 1
            }
            set new_list: factory.new_node_list_like(copy, nodes)
        }
        if synthetic_location
        {
            let nl new_list as ref[Array[ref[AstNode]?]]
            if factory.list_has_trailing_comma(nodes)
            {
                let n nl.get_length() as int
                if n > 0
                {
                    let last nl[(n - 1) as size_t]
                    if last <> null
                    {
                        let ln last as ref[AstNode]
                        set ln.pos: 0 - 2
                        set ln.end: 0 - 2
                    }
                }
            }
        }
        new_list
    }
}

; getDeepCloneVisitor / DeepCloneNode / DeepCloneReparse
define DeepClone
(
    host: ref[Page]
)
{
    function visitor(host: ref[Page], f: ref[NodeFactory], synthetic_location: bool) returns ref[NodeVisitor]
    {
        let v NodeVisitor.create(host, f, VisitTagDeepClone, HooksTagDeepClone)
        set v.synthetic_location: synthetic_location
        v
    }

    procedure deep_clone_node(host: ref[Page], f: ref[NodeFactory], node: ref[AstNode]?) returns ref[AstNode]?
        DeepClone.visitor(host, f, true).visit_node(node)

    procedure deep_clone_reparse(host: ref[Page], f: ref[NodeFactory], node_in: ref[AstNode]?) returns ref[AstNode]?
    {
        if node_in = null
            return null
        let node DeepClone.visitor(host, f, false).visit_node(node_in)
        if node = null
            return null
        let n node as ref[AstNode]
        NodeFactory.set_parent_in_children(n)
        set n.flags: n.flags | NodeFlagsReparsed
        n
    }

    procedure deep_clone_reparse_modifiers(host: ref[Page], f: ref[NodeFactory], modifiers: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
        DeepClone.visitor(host, f, false).visit_modifiers(modifiers)
}
"""

FACTORY_EXTRAS = """
    ; ══ printer/factory.go — the emit-context factory's own constructors (slice 232),
    ; hand-written in the generator (this block is FACTORY_EXTRAS there). ═══════

    function the_context(this) returns ref[EmitContext]
        context as ref[EmitContext]

    function next_auto_id(this) returns int
        this.the_context().next_auto_id()

    ; The placeholder text of a generated identifier: `(auto@N)` or the
    ; original node's text or `(generated@N)`; the reference's N is a node id,
    ; this port's the node's address — never printed, only a key.
    function placeholder_text(this, tag: Slice[char], n: int) returns Slice[char]
    {
        let b StringBuilder^host()
        b.append("(" as char)
        b.append(tag.data, tag.length)
        b.append("@" as char)
        b.append(n)
        b.append(")" as char)
        Printer.slice_on(host, b.to_string())
    }

    procedure new_generated_identifier(this, kind: int, text_in: Slice[char], node: ref[AstNode]?, flags: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
    {
        let id this.next_auto_id()
        var text text_in
        if (text.length as int) = 0
        {
            if node = null
                set text: this.placeholder_text("auto", id)
            else
            {
                let n node as ref[AstNode]
                if (n.kind = KindIdentifier) or (n.kind = KindPrivateIdentifier)
                    set text: AstNode.identifier_text_of(n)
                else
                    set text: this.placeholder_text("generated", this.the_context().get_node_for_generated_name_worker(n, id) as int)
            }
            set text: Printer.slice_of(Printer.format_generated_name(host, false, prefix, text, suffix))
        }
        let name this.new_identifier(text)
        let info &AutoGenerateInfo^host(kind | (flags & ~GeneratedIdentifierFlagsKindMask), id, prefix, suffix, node)
        this.the_context().set_auto_generate_info(name, info)
        name
    }

    procedure new_temp_variable(this) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsAuto, "", null, 0, "", "")

    procedure new_temp_variable_ex(this, flags: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsAuto, "", null, flags, prefix, suffix)

    procedure new_loop_variable(this) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsLoop, "", null, 0, "", "")

    procedure new_loop_variable_ex(this, flags: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsLoop, "", null, flags, prefix, suffix)

    procedure new_unique_name(this, text: Slice[char]) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsUnique, text, null, 0, "", "")

    procedure new_unique_name_ex(this, text: Slice[char], flags: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsUnique, text, null, flags, prefix, suffix)

    procedure new_generated_name_for_node(this, node: ref[AstNode]) returns ref[AstNode]
        this.new_generated_identifier(GeneratedIdentifierFlagsNode, "", node, 0, "", "")

    procedure new_generated_name_for_node_ex(this, node: ref[AstNode], flags_in: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
    {
        var flags flags_in
        if ((prefix.length as int) > 0) or ((suffix.length as int) > 0)
            set flags: flags | GeneratedIdentifierFlagsOptimistic
        this.new_generated_identifier(GeneratedIdentifierFlagsNode, "", node, flags, prefix, suffix)
    }

    procedure new_generated_private_identifier(this, kind: int, text_in: Slice[char], node: ref[AstNode]?, flags: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
    {
        let id this.next_auto_id()
        var text text_in
        if (text.length as int) = 0
        {
            if node = null
                set text: this.placeholder_text("auto", id)
            else
            {
                let n node as ref[AstNode]
                if (n.kind = KindIdentifier) or (n.kind = KindPrivateIdentifier)
                    set text: AstNode.identifier_text_of(n)
                else
                    set text: this.placeholder_text("generated", this.the_context().get_node_for_generated_name_worker(n, id) as int)
            }
            set text: Printer.slice_of(Printer.format_generated_name(host, true, prefix, text, suffix))
        }
        let name this.new_private_identifier(text)
        let info &AutoGenerateInfo^host(kind | (flags & ~GeneratedIdentifierFlagsKindMask), id, prefix, suffix, node)
        this.the_context().set_auto_generate_info(name, info)
        name
    }

    procedure new_unique_private_name(this, text: Slice[char]) returns ref[AstNode]
        this.new_generated_private_identifier(GeneratedIdentifierFlagsUnique, text, null, 0, "", "")

    procedure new_unique_private_name_ex(this, text: Slice[char], flags: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
        this.new_generated_private_identifier(GeneratedIdentifierFlagsUnique, text, null, flags, prefix, suffix)

    procedure new_generated_private_name_for_node(this, node: ref[AstNode]) returns ref[AstNode]
        this.new_generated_private_identifier(GeneratedIdentifierFlagsNode, "", node, 0, "", "")

    procedure new_generated_private_name_for_node_ex(this, node: ref[AstNode], flags_in: int, prefix: Slice[char], suffix: Slice[char]) returns ref[AstNode]
    {
        var flags flags_in
        if ((prefix.length as int) > 0) or ((suffix.length as int) > 0)
            set flags: flags | GeneratedIdentifierFlagsOptimistic
        this.new_generated_private_identifier(GeneratedIdentifierFlagsNode, "", node, flags, prefix, suffix)
    }

    ; NewStringLiteralFromNode: a string literal whose text is the node's, with
    ; the node recorded as its text source.
    procedure new_string_literal_from_node(this, text_source_node: ref[AstNode]) returns ref[AstNode]
    {
        var text: Slice[char] ""
        let k text_source_node.kind
        if (k = KindIdentifier) or (k = KindPrivateIdentifier)
            set text: AstNode.identifier_text_of(text_source_node)
        else
        {
            if k = KindJsxNamespacedName
            {
                ; Node.Text() of a namespaced name: "ns:name".
                let b StringBuilder^host()
                let ns AstNode.identifier_text_of(AstNode.namespaced_namespace_of(text_source_node))
                b.append(ns.data, ns.length)
                b.append(":" as char)
                let nm AstNode.identifier_text_of(AstNode.namespaced_name_of(text_source_node))
                b.append(nm.data, nm.length)
                set text: Printer.slice_on(host, b.to_string())
            }
            else
            {
                if (k = KindStringLiteral) or (k = KindNumericLiteral) or (k = KindBigIntLiteral) or (k = KindNoSubstitutionTemplateLiteral) or (k = KindTemplateHead) or (k = KindTemplateMiddle) or (k = KindTemplateTail) or (k = KindRegularExpressionLiteral)
                    set text: AstNode.literal_text_of(text_source_node)
            }
        }
        let node this.new_string_literal(text, TokenFlagsNone)
        this.the_context().set_text_source(node, text_source_node)
        node
    }

    procedure new_this_expression(this) returns ref[AstNode]
        this.new_keyword_expression(KindThisKeyword)

    procedure new_true_expression(this) returns ref[AstNode]
        this.new_keyword_expression(KindTrueKeyword)

    procedure new_false_expression(this) returns ref[AstNode]
        this.new_keyword_expression(KindFalseKeyword)

    procedure new_comma_expression(this, left: ref[AstNode]?, right: ref[AstNode]?) returns ref[AstNode]
        this.new_binary_expression(null, left, null, this.new_token(KindCommaToken), right)

    procedure new_assignment_expression(this, left: ref[AstNode]?, right: ref[AstNode]?) returns ref[AstNode]
        this.new_binary_expression(null, left, null, this.new_token(KindEqualsToken), right)

    procedure new_logical_or_expression(this, left: ref[AstNode]?, right: ref[AstNode]?) returns ref[AstNode]
        this.new_binary_expression(null, left, null, this.new_token(KindBarBarToken), right)

    procedure new_logical_and_expression(this, left: ref[AstNode]?, right: ref[AstNode]?) returns ref[AstNode]
        this.new_binary_expression(null, left, null, this.new_token(KindAmpersandAmpersandToken), right)

    procedure new_strict_equality_expression(this, left: ref[AstNode]?, right: ref[AstNode]?) returns ref[AstNode]
        this.new_binary_expression(null, left, null, this.new_token(KindEqualsEqualsEqualsToken), right)

    procedure new_strict_inequality_expression(this, left: ref[AstNode]?, right: ref[AstNode]?) returns ref[AstNode]
        this.new_binary_expression(null, left, null, this.new_token(KindExclamationEqualsEqualsToken), right)

    procedure new_void_zero_expression(this) returns ref[AstNode]
        this.new_void_expression(this.new_numeric_literal("0", TokenFlagsNone))

    ; flattenCommaElements: synthesized comma expressions flattened.
    procedure flatten_comma_element(this, node: ref[AstNode], expressions: ref[Array[ref[AstNode]?]])
    {
        var comma false
        if node.kind = KindBinaryExpression
        {
            if node.pos < 0
            {
                let op AstNode.binary_operator_token_of(node)
                if op <> null
                {
                    if (op as ref[AstNode]).kind = KindCommaToken
                        set comma: true
                }
            }
        }
        if comma
        {
            let left AstNode.binary_left_of(node)
            let right AstNode.binary_right_of(node)
            if left <> null
                this.flatten_comma_element(left as ref[AstNode], expressions)
            if right <> null
                this.flatten_comma_element(right as ref[AstNode], expressions)
            return
        }
        expressions.add(node)
    }

    procedure inline_expressions(this, expressions: ref[Array[ref[AstNode]?]]) returns ref[AstNode]?
    {
        let n expressions.get_length() as int
        if n = 0
            return null
        if n = 1
            return expressions[0 as size_t]
        let flat &Array[ref[AstNode]?]^host()
        var i 0
        while i < n
        {
            let e expressions[i as size_t]
            if e <> null
                this.flatten_comma_element(e as ref[AstNode], flat)
            set i: i + 1
        }
        var expression flat[0 as size_t]
        set i: 1
        while i < (flat.get_length() as int)
        {
            set expression: this.new_comma_expression(expression, flat[i as size_t])
            set i: i + 1
        }
        expression
    }

    ; CreateExpressionFromEntityName: `a.b.c` from a qualified name, the parts
    ; cloned at their original locations and parents.
    procedure create_expression_from_entity_name(this, node: ref[AstNode]) returns ref[AstNode]
    {
        if node.kind = KindQualifiedName
        {
            let left this.create_expression_from_entity_name(AstNode.qualified_left_of(node) as ref[AstNode])
            let right_src AstNode.qualified_right_of(node) as ref[AstNode]
            let right this.clone(right_src)
            set right.pos: right_src.pos
            set right.end: right_src.end
            set right.parent: right_src.parent
            let prop_access this.new_property_access_expression(left, null, right, NodeFlagsNone)
            set prop_access.pos: node.pos
            set prop_access.end: node.end
            return prop_access
        }
        let res this.clone(node)
        set res.pos: node.pos
        set res.end: node.end
        set res.parent: node.parent
        res
    }

    procedure restore_enclosing_label(this, node: ref[AstNode], outermost_labeled_statement: ref[AstNode]?) returns ref[AstNode]
    {
        if outermost_labeled_statement = null
            return node
        let outer outermost_labeled_statement as ref[AstNode]
        var inner_label node
        let stmt AstNode.statement_of(outer)
        if stmt <> null
        {
            if (stmt as ref[AstNode]).kind = KindLabeledStatement
                set inner_label: this.restore_enclosing_label(node, stmt)
        }
        this.update_labeled_statement(outer, AstNode.label_name_of(outer), inner_label)
    }

    procedure create_for_of_binding_statement(this, node: ref[AstNode], bound_value: ref[AstNode]) returns ref[AstNode]
    {
        if node.kind = KindVariableDeclarationList
        {
            let decls AstNode.variable_declarations_of(node) as ref[Array[ref[AstNode]?]]
            let first_declaration decls[0 as size_t] as ref[AstNode]
            let updated_declaration this.update_variable_declaration(first_declaration, AstNode.name_of(first_declaration), null, null, bound_value)
            let one &Array[ref[AstNode]?]^host()
            one.add(updated_declaration)
            let statement this.new_variable_statement(null, this.update_variable_declaration_list(node, one, node.flags))
            set statement.pos: node.pos
            set statement.end: node.end
            return statement
        }
        let updated_expression this.new_assignment_expression(node, bound_value)
        set updated_expression.pos: node.pos
        set updated_expression.end: node.end
        let statement this.new_expression_statement(updated_expression)
        set statement.pos: node.pos
        set statement.end: node.end
        statement
    }

    ; NewTypeCheck: `value === null`, `value === void 0`, or `typeof value === "tag"`.
    procedure new_type_check(this, value: ref[AstNode], tag: Slice[char]) returns ref[AstNode]
    {
        if tag = "null"
            return this.new_strict_equality_expression(value, this.new_keyword_expression(KindNullKeyword))
        if tag = "undefined"
            return this.new_strict_equality_expression(value, this.new_void_zero_expression())
        this.new_strict_equality_expression(this.new_type_of_expression(value), this.new_string_literal(tag, TokenFlagsNone))
    }

    procedure new_method_call(this, object: ref[AstNode], method_name: ref[AstNode], arguments_list: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
    {
        var flags NodeFlagsNone
        if object.kind = KindCallExpression
        {
            if (object.flags & NodeFlagsOptionalChain) <> 0
                set flags: NodeFlagsOptionalChain
        }
        this.new_call_expression(this.new_property_access_expression(object, null, method_name, NodeFlagsNone), null, null, arguments_list, flags)
    }

    procedure new_global_method_call(this, global_object_name: Slice[char], method_name: Slice[char], arguments_list: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
        this.new_method_call(this.new_identifier(global_object_name), this.new_identifier(method_name), arguments_list)

    procedure new_function_call_call(this, target: ref[AstNode], this_arg: ref[AstNode], arguments_list: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
    {
        let args &Array[ref[AstNode]?]^host()
        args.add(this_arg)
        var i 0
        while i < (arguments_list.get_length() as int)
        {
            args.add(arguments_list[i as size_t])
            set i: i + 1
        }
        this.new_method_call(target, this.new_identifier("call"), args)
    }

    procedure new_array_slice_call(this, array: ref[AstNode], start: int) returns ref[AstNode]
    {
        let args &Array[ref[AstNode]?]^host()
        if start <> 0
        {
            let b StringBuilder^host()
            b.append(start)
            args.add(this.new_numeric_literal(Printer.slice_on(host, b.to_string()), TokenFlagsNone))
        }
        this.new_method_call(array, this.new_identifier("slice"), args)
    }

    function is_ignorable_paren(this, node: ref[AstNode]) returns bool
    {
        if node.kind <> KindParenthesizedExpression
            return false
        if node.pos >= 0
            return false
        let ctx this.the_context()
        if ctx.source_map_range(node).pos >= 0
            return false
        ctx.comment_range(node).pos < 0
    }

    procedure update_outer_expression(this, outer_expression: ref[AstNode], expression: ref[AstNode]?) returns ref[AstNode]
    {
        let k outer_expression.kind
        if k = KindParenthesizedExpression
            return this.update_parenthesized_expression(outer_expression, expression)
        if k = KindTypeAssertionExpression
            return this.update_type_assertion(outer_expression, AstNode.type_of(outer_expression), expression)
        if k = KindAsExpression
            return this.update_as_expression(outer_expression, expression, AstNode.type_of(outer_expression))
        if k = KindSatisfiesExpression
            return this.update_satisfies_expression(outer_expression, expression, AstNode.type_of(outer_expression))
        if k = KindNonNullExpression
            return this.update_non_null_expression(outer_expression, expression, outer_expression.flags)
        if k = KindExpressionWithTypeArguments
            return this.update_expression_with_type_arguments(outer_expression, expression, AstNode.type_arguments_of(outer_expression))
        if k = KindPartiallyEmittedExpression
            return this.update_partially_emitted_expression(outer_expression, expression)
        outer_expression
    }

    procedure restore_outer_expressions(this, outer_expression: ref[AstNode]?, inner_expression: ref[AstNode]?, kinds: int) returns ref[AstNode]?
    {
        if outer_expression <> null
        {
            let outer outer_expression as ref[AstNode]
            if Parser.is_outer_expression(outer, kinds)
            {
                if this.is_ignorable_paren(outer) = false
                    return this.update_outer_expression(outer, this.restore_outer_expressions(AstNode.expression_of(outer), inner_expression, OEKAll))
            }
        }
        inner_expression
    }

    ; EnsureUseStrict: a `"use strict"` prologue unless the first statement is one.
    procedure ensure_use_strict(this, statements: ref[Array[ref[AstNode]?]]) returns ref[Array[ref[AstNode]?]]
    {
        if (statements.get_length() as int) > 0
        {
            let first statements[0 as size_t]
            if EmitContext.is_prologue_directive(first)
            {
                let use_strict: Slice[char] "use strict"
                if EmitContext.prologue_text(first as ref[AstNode]).equals(use_strict)
                    return statements
            }
        }
        let use_strict_prologue this.new_expression_statement(this.new_string_literal("use strict", TokenFlagsNone))
        let out &Array[ref[AstNode]?]^host()
        out.add(use_strict_prologue)
        var i 0
        while i < (statements.get_length() as int)
        {
            out.add(statements[i as size_t])
            set i: i + 1
        }
        out
    }

    ; SplitStandardPrologue / SplitCustomPrologue: the index where the rest begins.
    function split_standard_prologue(this, source: ref[Array[ref[AstNode]?]]) returns int
    {
        var i 0
        while i < (source.get_length() as int)
        {
            if EmitContext.is_prologue_directive(source[i as size_t]) = false
                return i
            set i: i + 1
        }
        i
    }

    function split_custom_prologue(this, source: ref[Array[ref[AstNode]?]]) returns int
    {
        let ctx this.the_context()
        var i 0
        while i < (source.get_length() as int)
        {
            let s source[i as size_t]
            if EmitContext.is_prologue_directive(s)
                return i
            if s <> null
            {
                if (ctx.emit_flags(s as ref[AstNode]) & EFCustomPrologue) = 0
                    return i
            }
            set i: i + 1
        }
        i
    }

    ; ast.GetNameOfDeclaration / GetNonAssignedNameOfDeclaration over the port's
    ; name slot; a function or class expression falls back to its assigned name.
    function name_of_declaration(node: ref[AstNode]?, ignore_assigned: bool) returns ref[AstNode]?
    {
        if node = null
            return null
        let name AstNode.name_of(node)
        if name <> null
            return name
        if ignore_assigned
            return null
        let k (node as ref[AstNode]).kind
        if (k = KindFunctionExpression) or (k = KindArrowFunction) or (k = KindClassExpression)
            return Binder.get_assigned_name(node)
        null
    }

    procedure get_name(this, node: ref[AstNode]?, emit_flags_in: int, allow_comments: bool, allow_source_maps: bool, ignore_assigned_name: bool) returns ref[AstNode]
    {
        let node_name NodeFactory.name_of_declaration(node, ignore_assigned_name)
        if node_name <> null
        {
            let name this.clone(node_name as ref[AstNode])
            var emit_flags emit_flags_in
            if allow_comments = false
                set emit_flags: emit_flags | EFNoComments
            if allow_source_maps = false
                set emit_flags: emit_flags | EFNoSourceMap
            this.the_context().add_emit_flags(name, emit_flags)
            return name
        }
        this.new_generated_name_for_node(node as ref[AstNode])
    }

    procedure get_local_name(this, node: ref[AstNode]?) returns ref[AstNode]
        this.get_name(node, EFLocalName, false, false, false)

    procedure get_local_name_ex(this, node: ref[AstNode]?, allow_comments: bool, allow_source_maps: bool, ignore_assigned_name: bool) returns ref[AstNode]
        this.get_name(node, EFLocalName, allow_comments, allow_source_maps, ignore_assigned_name)

    procedure get_export_name(this, node: ref[AstNode]?) returns ref[AstNode]
        this.get_name(node, EFExportName, false, false, false)

    procedure get_export_name_ex(this, node: ref[AstNode]?, allow_comments: bool, allow_source_maps: bool, ignore_assigned_name: bool) returns ref[AstNode]
        this.get_name(node, EFExportName, allow_comments, allow_source_maps, ignore_assigned_name)

    procedure get_declaration_name(this, node: ref[AstNode]?) returns ref[AstNode]
        this.get_name(node, EFNone, false, false, false)

    procedure get_declaration_name_ex(this, node: ref[AstNode]?, allow_comments: bool, allow_source_maps: bool) returns ref[AstNode]
        this.get_name(node, EFNone, allow_comments, allow_source_maps, false)

    procedure get_namespace_member_name(this, ns: ref[AstNode], name_in: ref[AstNode], allow_comments: bool, allow_source_maps: bool) returns ref[AstNode]
    {
        let ctx this.the_context()
        var name name_in
        if ctx.has_auto_generate_info(name) = false
            set name: this.clone(name)
        let qualified_name this.new_property_access_expression(ns, null, name, NodeFlagsNone)
        ctx.assign_comment_and_source_map_ranges(qualified_name, name)
        if allow_comments = false
            ctx.add_emit_flags(qualified_name, EFNoComments)
        if allow_source_maps = false
            ctx.add_emit_flags(qualified_name, EFNoSourceMap)
        qualified_name
    }

    ; ast.HasSyntacticModifier(node, Export): a modifier of the kind is present.
    function has_export_modifier(node: ref[AstNode]) returns bool
    {
        let modifiers AstNode.modifiers_of(node)
        if modifiers = null
            return false
        let list modifiers as ref[Array[ref[AstNode]?]]
        var i 0
        while i < (list.get_length() as int)
        {
            let m list[i as size_t]
            if m <> null
            {
                if (m as ref[AstNode]).kind = KindExportKeyword
                    return true
            }
            set i: i + 1
        }
        false
    }

    procedure get_external_module_or_namespace_export_name(this, ns: ref[AstNode]?, node: ref[AstNode], allow_comments: bool, allow_source_maps: bool) returns ref[AstNode]
    {
        if ns <> null
        {
            if NodeFactory.has_export_modifier(node)
                return this.get_namespace_member_name(ns as ref[AstNode], this.get_declaration_name_ex(node, allow_comments, allow_source_maps), allow_comments, allow_source_maps)
        }
        this.get_export_name_ex(node, allow_comments, allow_source_maps, false)
    }

    procedure new_unscoped_helper_name(this, name: Slice[char]) returns ref[AstNode]
    {
        let node this.new_identifier(name)
        this.the_context().set_emit_flags(node, EFHelperName)
        node
    }

    procedure helper_call(this, name: Slice[char], args: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
        this.new_call_expression(this.new_unscoped_helper_name(name), null, null, args, NodeFlagsNone)

    function list1(this, a: ref[AstNode]?) returns ref[Array[ref[AstNode]?]]
    {
        let l &Array[ref[AstNode]?]^host()
        l.add(a)
        l
    }

    function list2(this, a: ref[AstNode]?, b: ref[AstNode]?) returns ref[Array[ref[AstNode]?]]
    {
        let l &Array[ref[AstNode]?]^host()
        l.add(a)
        l.add(b)
        l
    }

    function list3(this, a: ref[AstNode]?, b: ref[AstNode]?, c: ref[AstNode]?) returns ref[Array[ref[AstNode]?]]
    {
        let l &Array[ref[AstNode]?]^host()
        l.add(a)
        l.add(b)
        l.add(c)
        l
    }

    procedure new_decorate_helper(this, decorator_expressions: ref[Array[ref[AstNode]?]], target: ref[AstNode], member_name: ref[AstNode]?, descriptor: ref[AstNode]?) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.decorate_helper)
        let args &Array[ref[AstNode]?]^host()
        args.add(this.new_array_literal_expression(decorator_expressions, true))
        args.add(target)
        if member_name <> null
        {
            args.add(member_name)
            if descriptor <> null
                args.add(descriptor)
        }
        this.helper_call("__decorate", args)
    }

    procedure new_metadata_helper(this, metadata_key: Slice[char], metadata_value: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.metadata_helper)
        this.helper_call("__metadata", this.list2(this.new_string_literal(metadata_key, TokenFlagsNone), metadata_value))
    }

    procedure new_param_helper(this, expression: ref[AstNode], parameter_offset: int, location: TextRange) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.param_helper)
        let b StringBuilder^host()
        b.append(parameter_offset)
        let helper this.helper_call("__param", this.list2(this.new_numeric_literal(Printer.slice_on(host, b.to_string()), TokenFlagsNone), expression))
        set helper.pos: location.pos
        set helper.end: location.end
        helper
    }

    procedure new_add_disposable_resource_helper(this, env_binding: ref[AstNode], value: ref[AstNode], async: bool) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.add_disposable_resource_helper)
        var flag KindFalseKeyword
        if async
            set flag: KindTrueKeyword
        this.helper_call("__addDisposableResource", this.list3(env_binding, value, this.new_keyword_expression(flag)))
    }

    procedure new_dispose_resources_helper(this, env_binding: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.dispose_resources_helper)
        this.helper_call("__disposeResources", this.list1(env_binding))
    }

    ; The private-identifier kinds are the strings "f", "m", "a", "untransformed".
    procedure new_class_private_field_get_helper(this, receiver: ref[AstNode], state: ref[AstNode], kind: Slice[char], fn: ref[AstNode]?) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.class_private_field_get_helper)
        let args this.list3(receiver, state, this.new_string_literal(kind, TokenFlagsNone))
        if fn <> null
            args.add(fn)
        this.helper_call("__classPrivateFieldGet", args)
    }

    procedure new_class_private_field_set_helper(this, receiver: ref[AstNode], state: ref[AstNode], value: ref[AstNode], kind: Slice[char], fn: ref[AstNode]?) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.class_private_field_set_helper)
        let args this.list3(receiver, state, value)
        args.add(this.new_string_literal(kind, TokenFlagsNone))
        if fn <> null
            args.add(fn)
        this.helper_call("__classPrivateFieldSet", args)
    }

    procedure new_class_private_field_in_helper(this, state: ref[AstNode], receiver: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.class_private_field_in_helper)
        this.helper_call("__classPrivateFieldIn", this.list2(state, receiver))
    }

    procedure new_object_define_property_call(this, target: ref[AstNode], name: ref[AstNode], descriptor: ref[AstNode]) returns ref[AstNode]
        this.new_call_expression(this.new_property_access_expression(this.new_identifier("Object"), null, this.new_identifier("defineProperty"), NodeFlagsNone), null, null, this.list3(target, name, descriptor), NodeFlagsNone)

    procedure new_reflect_get_call(this, target: ref[AstNode], property_key: ref[AstNode], receiver: ref[AstNode]) returns ref[AstNode]
        this.new_call_expression(this.new_property_access_expression(this.new_identifier("Reflect"), null, this.new_identifier("get"), NodeFlagsNone), null, null, this.list3(target, property_key, receiver), NodeFlagsNone)

    procedure new_reflect_set_call(this, target: ref[AstNode], property_key: ref[AstNode], value: ref[AstNode], receiver: ref[AstNode]) returns ref[AstNode]
    {
        let args this.list3(target, property_key, value)
        args.add(receiver)
        this.new_call_expression(this.new_property_access_expression(this.new_identifier("Reflect"), null, this.new_identifier("set"), NodeFlagsNone), null, null, args, NodeFlagsNone)
    }

    procedure new_function_bind_call(this, target: ref[AstNode], this_arg: ref[AstNode], arguments_list: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
    {
        let args this.list1(this_arg)
        var i 0
        while i < (arguments_list.get_length() as int)
        {
            args.add(arguments_list[i as size_t])
            set i: i + 1
        }
        this.new_method_call(target, this.new_identifier("bind"), args)
    }

    procedure new_immediately_invoked_arrow_function(this, statements: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
    {
        let no_params &Array[ref[AstNode]?]^host()
        let arrow this.new_arrow_function(null, null, no_params, null, null, this.new_token(KindEqualsGreaterThanToken), this.new_block(statements, true))
        let no_args &Array[ref[AstNode]?]^host()
        this.new_call_expression(this.new_parenthesized_expression(arrow), null, null, no_args, NodeFlagsNone)
    }

    procedure new_export_default(this, expression: ref[AstNode]) returns ref[AstNode]
        this.new_export_assignment(null, false, null, expression)

    procedure new_external_module_export(this, name: ref[AstNode]) returns ref[AstNode]
    {
        let specifier this.new_export_specifier(false, null, name)
        let named_exports this.new_named_exports(this.list1(specifier))
        this.new_export_declaration(null, false, named_exports, null, null)
    }

    procedure new_assign_helper(this, attributes_segments: ref[Array[ref[AstNode]?]]) returns ref[AstNode]
        this.new_call_expression(this.new_property_access_expression(this.new_identifier("Object"), null, this.new_identifier("assign"), NodeFlagsNone), null, null, attributes_segments, NodeFlagsNone)

    procedure new_await_helper(this, expression: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.await_helper)
        this.helper_call("__await", this.list1(expression))
    }

    procedure new_async_generator_helper(this, generator_func: ref[AstNode], has_lexical_this: bool) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.await_helper)
        ctx.request_emit_helper(ctx.helpers.async_generator_helper)
        ctx.add_emit_flags(generator_func, EFAsyncFunctionBody | EFReuseTempVariableScope)
        var this_arg this.new_void_zero_expression()
        if has_lexical_this
            set this_arg: this.new_keyword_expression(KindThisKeyword)
        this.helper_call("__asyncGenerator", this.list3(this_arg, this.new_identifier("arguments"), generator_func))
    }

    procedure new_async_delegator_helper(this, expression: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.await_helper)
        ctx.request_emit_helper(ctx.helpers.async_delegator_helper)
        this.helper_call("__asyncDelegator", this.list1(expression))
    }

    procedure new_async_values_helper(this, expression: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.async_values_helper)
        this.helper_call("__asyncValues", this.list1(expression))
    }

    procedure new_awaiter_helper(this, has_lexical_this: bool, arguments_expression: ref[AstNode]?, parameters: ref[Array[ref[AstNode]?]]?, body: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.awaiter_helper)
        var params: ref[Array[ref[AstNode]?]]? parameters
        if params = null
            set params: &Array[ref[AstNode]?]^host()
        let generator_func this.new_function_expression(null, this.new_token(KindAsteriskToken), null, null, params, null, null, body)
        ctx.add_emit_flags(generator_func, EFAsyncFunctionBody | EFReuseTempVariableScope)
        var this_arg this.new_void_zero_expression()
        if has_lexical_this
            set this_arg: this.new_keyword_expression(KindThisKeyword)
        var args_arg this.new_void_zero_expression()
        if arguments_expression <> null
            set args_arg: arguments_expression as ref[AstNode]
        let args this.list3(this_arg, args_arg, this.new_void_zero_expression())
        args.add(generator_func)
        this.helper_call("__awaiter", args)
    }

    procedure new_es_decorate_class_context_object(this, name_expr: ref[AstNode]?, metadata: ref[AstNode]?) returns ref[AstNode]
    {
        let props this.list3(
            this.new_property_assignment(null, this.new_identifier("kind"), null, null, this.new_string_literal("class", TokenFlagsNone)),
            this.new_property_assignment(null, this.new_identifier("name"), null, null, name_expr),
            this.new_property_assignment(null, this.new_identifier("metadata"), null, null, metadata))
        this.new_object_literal_expression(props, false)
    }

    procedure es_decorate_accessor(this, name_computed: bool, name_expr: ref[AstNode]?) returns ref[AstNode]
    {
        if name_computed
            return this.new_element_access_expression(this.new_identifier("obj"), null, name_expr, NodeFlagsNone)
        this.new_property_access_expression(this.new_identifier("obj"), null, name_expr, NodeFlagsNone)
    }

    procedure new_es_decorate_class_element_access_get_method(this, name_computed: bool, name_expr: ref[AstNode]?) returns ref[AstNode]
    {
        let accessor this.es_decorate_accessor(name_computed, name_expr)
        let obj_param this.new_parameter_declaration(null, null, this.new_identifier("obj"), null, null, null)
        let arrow this.new_arrow_function(null, null, this.list1(obj_param), null, null, this.new_token(KindEqualsGreaterThanToken), accessor)
        this.new_property_assignment(null, this.new_identifier("get"), null, null, arrow)
    }

    procedure new_es_decorate_class_element_access_set_method(this, name_computed: bool, name_expr: ref[AstNode]?) returns ref[AstNode]
    {
        let accessor this.es_decorate_accessor(name_computed, name_expr)
        let assignment this.new_assignment_expression(accessor, this.new_identifier("value"))
        let stmt this.new_expression_statement(assignment)
        let body this.new_block(this.list1(stmt), false)
        let obj_param this.new_parameter_declaration(null, null, this.new_identifier("obj"), null, null, null)
        let value_param this.new_parameter_declaration(null, null, this.new_identifier("value"), null, null, null)
        let arrow this.new_arrow_function(null, null, this.list2(obj_param, value_param), null, null, this.new_token(KindEqualsGreaterThanToken), body)
        this.new_property_assignment(null, this.new_identifier("set"), null, null, arrow)
    }

    procedure new_es_decorate_class_element_access_has_method(this, name_computed: bool, name_expr: ref[AstNode]?) returns ref[AstNode]
    {
        var property_name name_expr
        if name_computed = false
        {
            if name_expr <> null
            {
                if (name_expr as ref[AstNode]).kind = KindIdentifier
                    set property_name: this.new_string_literal_from_node(name_expr as ref[AstNode])
            }
        }
        let obj_param this.new_parameter_declaration(null, null, this.new_identifier("obj"), null, null, null)
        let in_expr this.new_binary_expression(null, property_name, null, this.new_token(KindInKeyword), this.new_identifier("obj"))
        let arrow this.new_arrow_function(null, null, this.list1(obj_param), null, null, this.new_token(KindEqualsGreaterThanToken), in_expr)
        this.new_property_assignment(null, this.new_identifier("has"), null, null, arrow)
    }

    procedure new_es_decorate_class_element_access_object(this, name_computed: bool, name_expr: ref[AstNode]?, has_get: bool, has_set: bool) returns ref[AstNode]
    {
        let access_props this.list1(this.new_es_decorate_class_element_access_has_method(name_computed, name_expr))
        if has_get
            access_props.add(this.new_es_decorate_class_element_access_get_method(name_computed, name_expr))
        if has_set
            access_props.add(this.new_es_decorate_class_element_access_set_method(name_computed, name_expr))
        this.new_object_literal_expression(access_props, false)
    }

    procedure new_es_decorate_class_element_context_object(this, kind: Slice[char], name_computed: bool, name_expr: ref[AstNode]?, is_static: bool, is_private: bool, has_get: bool, has_set: bool, metadata: ref[AstNode]?) returns ref[AstNode]
    {
        var name_value name_expr
        if name_computed = false
        {
            if name_expr <> null
            {
                let nk (name_expr as ref[AstNode]).kind
                if (nk = KindPrivateIdentifier) or (nk = KindIdentifier)
                    set name_value: this.new_string_literal_from_node(name_expr as ref[AstNode])
            }
        }
        let access_obj this.new_es_decorate_class_element_access_object(name_computed, name_expr, has_get, has_set)
        var static_expr this.new_false_expression()
        if is_static
            set static_expr: this.new_true_expression()
        var private_expr this.new_false_expression()
        if is_private
            set private_expr: this.new_true_expression()
        let props this.list3(
            this.new_property_assignment(null, this.new_identifier("kind"), null, null, this.new_string_literal(kind, TokenFlagsNone)),
            this.new_property_assignment(null, this.new_identifier("name"), null, null, name_value),
            this.new_property_assignment(null, this.new_identifier("static"), null, null, static_expr))
        props.add(this.new_property_assignment(null, this.new_identifier("private"), null, null, private_expr))
        props.add(this.new_property_assignment(null, this.new_identifier("access"), null, null, access_obj))
        props.add(this.new_property_assignment(null, this.new_identifier("metadata"), null, null, metadata))
        this.new_object_literal_expression(props, false)
    }

    procedure new_es_decorate_helper(this, ctor: ref[AstNode], descriptor_in: ref[AstNode], decorators: ref[AstNode], context_in: ref[AstNode], initializers: ref[AstNode], extra_initializers: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.es_decorate_helper)
        let args this.list3(ctor, descriptor_in, decorators)
        args.add(context_in)
        args.add(initializers)
        args.add(extra_initializers)
        this.helper_call("__esDecorate", args)
    }

    procedure new_run_initializers_helper(this, this_arg: ref[AstNode], initializers: ref[AstNode], value: ref[AstNode]?) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.run_initializers_helper)
        let args this.list2(this_arg, initializers)
        if value <> null
            args.add(value)
        this.helper_call("__runInitializers", args)
    }

    procedure new_template_object_helper(this, cooked_array: ref[AstNode], raw_array: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.make_template_object_helper)
        this.helper_call("__makeTemplateObject", this.list2(cooked_array, raw_array))
    }

    procedure new_prop_key_helper(this, expr: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.prop_key_helper)
        this.helper_call("__propKey", this.list1(expr))
    }

    procedure new_set_function_name_helper(this, fn: ref[AstNode], name: ref[AstNode], prefix: Slice[char]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.set_function_name_helper)
        let args this.list2(fn, name)
        if (prefix.length as int) > 0
            args.add(this.new_string_literal(prefix, TokenFlagsNone))
        this.helper_call("__setFunctionName", args)
    }

    procedure new_import_default_helper(this, expression: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.import_default_helper)
        this.helper_call("__importDefault", this.list1(expression))
    }

    procedure new_import_star_helper(this, expression: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.import_star_helper)
        this.helper_call("__importStar", this.list1(expression))
    }

    procedure new_export_star_helper(this, module_expression: ref[AstNode], exports_expression: ref[AstNode]) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.export_star_helper)
        this.helper_call("__exportStar", this.list2(module_expression, exports_expression))
    }

    procedure new_assignment_target_wrapper(this, param_name: ref[AstNode], expression: ref[AstNode]) returns ref[AstNode]
    {
        let param this.new_parameter_declaration(null, null, param_name, null, null, null)
        let body this.new_block(this.list1(this.new_expression_statement(expression)), false)
        let set_accessor this.new_set_accessor_declaration(null, this.new_identifier("value"), null, this.list1(param), null, null, body)
        let obj_literal this.new_object_literal_expression(this.list1(set_accessor), false)
        this.new_property_access_expression(this.new_parenthesized_expression(obj_literal), null, this.new_identifier("value"), NodeFlagsNone)
    }

    procedure new_rewrite_relative_import_extensions_helper(this, first_argument: ref[AstNode], preserve_jsx: bool) returns ref[AstNode]
    {
        let ctx this.the_context()
        ctx.request_emit_helper(ctx.helpers.rewrite_relative_import_extensions_helper)
        let args this.list1(first_argument)
        if preserve_jsx
            args.add(this.new_token(KindTrueKeyword))
        this.helper_call("__rewriteRelativeImportExtension", args)
    }

    ; NewRestHelper needs TryGetPropertyNameOfBindingOrAssignmentElement, which
    ; lands with the destructuring transform's slice.
"""

lines = []
def out(s=''): lines.append(s)

# ── header ──
out('''; SPDX-License-Identifier: Apache-2.0
;
; factory — internal/ast's NODE FACTORY and NODE VISITOR, GENERATED by
; packages/tscaly/tools/genfactory.py from the reference's ast_generated.go against
; this port's node records (slice 231). ★DO NOT EDIT the generated block; edit the
; generator (the hand-written visitor block at the end is part of the generator's
; FACTORY_TAIL). Field mapping: snake case, `Type` → `type_node`, and the override
; table in the generator where the port named a slot differently or shares a
; record between kinds. A constructor parameter the port's record has no slot for
; is accepted and DROPPED (template raw text and flags, JSDoc link text, the
; checker-internal synthetic expression) — each is named in the generator.
;
; ★ The factory belongs to an emit: `context` is the printer's EmitContext whose
; three hooks (OnCreate marks a node synthesized, OnUpdate/OnClone record the
; original) run when it is set; a factory without one (the deep-clone visitor's
; default) runs none, as the reference's zero NodeFactory does. `list_ranges` is
; the source file's list-range table, so a list a visitor rebuilds keeps the
; extent the original had (the reference copies `list.Loc`).

use scaly.memory.Page
use scaly.containers.Array
use tscaly.ast.*
use tscaly.printer.EmitContext
use tscaly.printer.EmitHelper
use tscaly.printer.EmitHelpers
use tscaly.printer.EmitNode
use tscaly.emitter.Transformer
use tscaly.printer.AutoGenerateInfo
use tscaly.printer.Printer
use tscaly.printer.TextRange
use tscaly.parser.Parser
use tscaly.binder.Binder
use scaly.containers.StringBuilder

define NodeFactory
(
    host: ref[Page]
    context: ref[EmitContext]?
    list_ranges: ref[Array[ListRange]]?
    node_count: int
    text_count: int
)
{
    function create(host: ref[Page], context: ref[EmitContext]?, list_ranges: ref[Array[ListRange]]?) returns ref[NodeFactory]
        &NodeFactory^host(host, context, list_ranges, 0, 0)

    ; newNode: raw region memory, every slot set (AstNode.alloc zero-fills nothing),
    ; the location undefined (-1, -1), then the context's OnCreate.
    procedure new_node(this, kind: int, data: NodeData) returns ref[AstNode]
    {
        let n AstNode.alloc(host)
        set n.kind: kind
        set n.flags: NodeFlagsNone
        set n.pos: 0 - 1
        set n.end: 0 - 1
        set n.data: data
        set n.parent: null
        set n.symbol: null
        set n.local_symbol: null
        set n.locals: null
        set n.flow_node: null
        set n.end_flow_node: null
        set n.return_flow_node: null
        set n.fallthrough_flow_node: null
        set n.original: null
        set n.emit_index: 0
        set n.emit_context_id: 0
        set n.subtree_facts: 0
        set this.node_count: node_count + 1
        if context <> null
            (context as ref[EmitContext]).on_create(n)
        n
    }

    ; updateNode: a changed node takes the original's flags and location, and the
    ; context records the original.
    procedure update_node(this, updated: ref[AstNode], original: ref[AstNode]) returns ref[AstNode]
    {
        if updated <> original
        {
            set updated.flags: original.flags
            set updated.pos: original.pos
            set updated.end: original.end
            if context <> null
                (context as ref[EmitContext]).on_update(updated, original)
        }
        updated
    }

    ; UpdateSourceFile (ast.go, hand-written in the reference): a copy of the
    ; node carrying the new statement list and token, else the node itself
    procedure update_source_file(this, node: ref[AstNode], statements: ref[Array[ref[AstNode]?]]?, end_of_file_token: ref[AstNode]?) returns ref[AstNode]
    {
        choose node.data
            when sf: SourceFile
            {
                if (sf.statements = statements) and (sf.end_of_file_token = end_of_file_token)
                    return node
                var d sf
                set d.statements: statements
                set d.end_of_file_token: end_of_file_token
                let c AstNode.alloc(host)
                set c: node
                set c.subtree_facts: 0
                set c.data: NodeData.SourceFile(d)
                return this.update_node(c, node)
            }
        node
    }

    procedure clone_node(this, updated: ref[AstNode], original: ref[AstNode]) returns ref[AstNode]
    {
        this.update_node(updated, original)
        if updated <> original
        {
            if context <> null
                (context as ref[EmitContext]).on_clone(updated, original)
        }
        updated
    }

    ; NewNodeList over a list the visitor rebuilt: a fresh Array with the same
    ; elements' extent as `like` (`list.Loc = nodes.Loc`), recorded in the file's table.
    procedure new_node_list_like(this, nodes: ref[Array[ref[AstNode]?]], like: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]
    {
        if list_ranges <> null
        {
            if like <> null
            {
                var p 0
                var e 0
                if AstNode.find_list_range(list_ranges, like, &p, &e)
                    (list_ranges as ref[Array[ListRange]]).add(ListRange(nodes, p, e))
            }
        }
        nodes
    }

    function empty_text() returns Slice[char]
        ""

    ; NodeList.HasTrailingComma: the last element ends before the list does. A
    ; list with no recorded extent has the reference's undefined (-1, -1), so a
    ; last element at (-2, -2) — the deep clone's marker — answers true.
    function list_has_trailing_comma(this, nodes: ref[Array[ref[AstNode]?]]?) returns bool
    {
        if nodes = null
            return false
        let list nodes as ref[Array[ref[AstNode]?]]
        let n list.get_length() as int
        if n = 0
            return false
        let last list[(n - 1) as size_t]
        if last = null
            return false
        var p 0 - 1
        var e 0 - 1
        if list_ranges <> null
            AstNode.find_list_range(list_ranges, nodes, &p, &e)
        (last as ref[AstNode]).end < e
    }

    ; SetParentInChildren, over the port's child enumerator.
    function set_parent_in_children(node: ref[AstNode])
    {
        var i 0
        while true
        {
            let c AstNode.child_at(node, i)
            if c = null
                break
            let child c as ref[AstNode]
            set child.parent: node
            NodeFactory.set_parent_in_children(child)
            set i: i + 1
        }
    }
''')

# ── per-kind constructors and updaters ──
order = sorted(news.keys(), key=lambda n: gen.find('NewFunc%s(' % n) if False else gen.find('func (f *NodeFactory) New%s(' % n))
for name in order:
    if name in SKIP: continue
    info = news[name]
    plist = info['params']
    arm_list = arms_for(name, info)
    kind_param = plist and plist[0][0] == 'kind'
    recs = []
    for a in arm_list:
        if a not in arms:
            problems.append('NO ARM for %s (kind %s → arm %s)' % (name, info['kind'], a)); recs = None; break
        recs.append(arms[a])
    if recs is None: continue
    record = recs[0]
    if any(r != record for r in recs):
        problems.append('ARMS DIFFER IN RECORD for %s: %s' % (name, recs)); continue
    fields = records.get(record)
    if fields is None:
        problems.append('NO RECORD %s for %s' % (record, name)); continue
    # param → field
    p2f = {}
    for gofield, param in info['assigns']:
        f = map_field(name, gofield, record)
        if f is None:
            problems.append('NO FIELD for %s.%s in %s %s' % (name, gofield, record, [x for x, _ in fields])); f = ''
        p2f[param] = f
    # parameters in Go order, typed by the mapped field
    ftype = dict(fields)
    def opt_type(t):
        if t.startswith('ref[') and not t.endswith('?'): return t + '?'
        return t
    sparams = []
    for pn, pt in plist:
        if pn == 'kind': sparams.append(('kind', 'int')); continue
        f = p2f.get(pn, None)
        if f: sparams.append((snake(pn), opt_type(ftype[f])))
        else: sparams.append((snake(pn), go_type_to_scaly(pt)))
    f2p = {f: snake(p) for p, f in p2f.items() if f}
    args = []
    for f, t in fields:
        a = f2p.get(f, None)
        if a is None: args.append(default_of(t)); continue
        if t.startswith('ref[') and not t.endswith('?'): args.append('(%s as %s)' % (a, t))
        else: args.append(a)
    fn = snake(name)
    sig = ', '.join('%s: %s' % (a, b) for a, b in sparams)
    out('    ; New%s' % name)
    out('    procedure new_%s(this%s) returns ref[AstNode]' % (fn, (', ' + sig) if sig else ''))
    out('    {')
    body = 'NodeData.%s(%s(%s))'
    def ctor(arm):
        return body % (arm, record, ', '.join(args))
    if kind_param:
        if len(arm_list) == 1:
            out('        let n this.new_node(kind, %s)' % ctor(arm_list[0]))
        else:
            out('        var n: ref[AstNode]? null')
            for i, a in enumerate(arm_list):
                if i < len(arm_list) - 1:
                    out('        if kind = Kind%s' % a)
                    out('            set n: this.new_node(kind, %s)' % ctor(a))
                else:
                    out('        if n = null')
                    out('            set n: this.new_node(kind, %s)' % ctor(a))
            out('        let node n as ref[AstNode]')
    else:
        out('        let n this.new_node(%s, %s)' % (info['kind'], ctor(arm_list[0])))
    nvar = 'node' if (kind_param and len(arm_list) > 1) else 'n'
    if info['flags']:
        op, expr = info['flags']
        expr = expr.replace('NodeFlagsOptionalChain', 'NodeFlagsOptionalChain')
        if op == '|=': out('        set %s.flags: %s.flags | (%s)' % (nvar, nvar, expr))
        else: out('        set %s.flags: %s' % (nvar, expr))
    out('        %s' % nvar)
    out('    }')
    out()
    # update
    if name in updates:
        cond = updates[name]
        cmp_params = re.findall(r'(\w+) != node\.(\w+)', cond)
        usig = ', '.join('%s: %s' % (a, b) for a, b in sparams if a != 'kind')
        out('    ; Update%s' % name)
        out('    procedure update_%s(this, node: ref[AstNode]%s) returns ref[AstNode]' % (fn, (', ' + usig) if usig else ''))
        out('    {')
        callargs = ', '.join(['node.kind' if a == 'kind' else a for a, _ in sparams])
        out('        choose node.data')
        for a in arm_list:
            out('            when d: %s' % a)
            out('            {')
            out('                var changed false')
            for pn, nf in cmp_params:
                if nf == 'Flags':
                    out('                if %s <> node.flags' % snake(pn)); out('                    set changed: true'); continue
                f = p2f.get(pn, '')
                if not f: continue
                t = ftype[f]
                if t.startswith('ref['):
                    out('                let cmp_%s: %s d.%s' % (f, opt_type(t), f))
                    out('                if %s <> cmp_%s' % (snake(pn), f))
                else:
                    out('                if %s <> d.%s' % (snake(pn), f))
                out('                    set changed: true')
            out('                if changed')
            out('                    return this.update_node(this.new_%s(%s), node)' % (fn, callargs))
            out('                return node')
            out('            }')
        out('        node')
        out('    }')
        out()

# the hand-written printer/factory.go block, then clone (both inside NodeFactory)
out(FACTORY_EXTRAS)
out("""    ; Clone, per kind (generated): a new node over the same children, then cloneNode.
    procedure clone(this, node: ref[AstNode]) returns ref[AstNode]
    {
        choose node.data""")
cloned_arms = set()
for name in order:
    if name in SKIP or name not in clones: continue
    newname, argtext = clones[name]
    info = news[name]
    arm_list = arms_for(name, info)
    if any(a not in arms for a in arm_list): continue
    record = arms[arm_list[0]]
    args = []; ok = True
    for a in [x.strip() for x in argtext.split(',')] if argtext.strip() else []:
        m = re.match(r'node\.(\w+)(\(\))?$', a)
        if not m: ok = False; break
        gname = m.group(1)
        if gname == 'Kind': args.append('node.kind'); continue
        if gname == 'Flags': args.append('node.flags'); continue
        f = map_field(name, gname, record)
        if f is None: ok = False; break
        if f == '': args.append('NodeFactory.empty_text()' if gname in ('RawText', 'Text', 'text') else 'null'); continue
        args.append('d.%s' % f)
    if not ok:
        problems.append('CLONE args unparsed for %s: %s' % (name, argtext)); continue
    for a in arm_list:
        if a in cloned_arms: continue
        cloned_arms.add(a)
        out('            when d: %s' % a)
        out('                return this.clone_node(this.new_%s(%s), node)' % (snake(name), ', '.join(args)))
out('        node')
out('    }')
out('}')
out()

# ── the visitor ──
out('''; ast.NodeVisitor. `visit_tag` names the callback the reference passes as a func
; value (§3.18): the deep-clone visitor here, each transformer in its own slice.
; `hooks_tag` names the hook set: none, the emit context's, the deep clone's.
define VisitTagNone: int 0
define VisitTagDeepClone: int 1
define VisitTagTransformer: int 2

define NodeVisitor
(
    host: ref[Page]
    factory: ref[NodeFactory]
    visit_tag: int
    hooks_tag: int
    synthetic_location: bool
    context: ref[EmitContext]?
    transformer: ref[Transformer]?
)
{
    function create(host: ref[Page], factory: ref[NodeFactory], visit_tag: int, hooks_tag: int) returns ref[NodeVisitor]
        &NodeVisitor^host(host, factory, visit_tag, hooks_tag, false, null, null)

    ; VisitEachChild: the per-kind dispatch (generated).
    procedure visit_each_child(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if node = null
            return null
        if visit_tag = VisitTagNone
            return node
        let n node as ref[AstNode]
        ; SourceFile: its VisitEachChild is hand-written in the reference (ast.go),
        ; not generated — the statements, then the end-of-file token
        if n.kind = KindSourceFile
            return factory.update_source_file(n, this.visit_nodes_h(AstNode.statements_of(n)), this.visit_token_h(AstNode.end_of_file_token_of(n)))
        choose n.data''')
for arm, rec in arms.items():
    # find the Go struct whose visit applies to this arm
    pass
visited_arms = set()
for name in order:
    if name in SKIP or name not in visits: continue
    upd, argtext = visits[name]
    info = news[name]
    arm_list = arms_for(name, info)
    if any(a not in arms for a in arm_list): continue
    record = arms[arm_list[0]]
    # parse args: v.visitX(node.Field) | node.Field | node.Kind | node.Modifiers()
    args = []
    ok = True
    for a in [x.strip() for x in re.split(r',\s*(?=v\.|node\.)', argtext)]:
        m = re.match(r'v\.(visit\w+)\(node\.(\w+)(\(\))?\)$', a)
        if m:
            f = map_field(name, m.group(2), record)
            if f is None: ok = False; break
            args.append('this.%s_h(d.%s)' % (snake(m.group(1)), f))
            continue
        m = re.match(r'node\.(\w+)(\(\))?$', a)
        if m:
            g = m.group(1)
            if g == 'Kind': args.append('n.kind'); continue
            if g == 'Flags': args.append('n.flags'); continue
            f = map_field(name, g, record)
            if f is None: ok = False; break
            args.append('d.%s' % f); continue
        ok = False; break
    if not ok:
        problems.append('VISIT args unparsed for %s: %s' % (name, argtext)); continue
    for a in arm_list:
        if a in visited_arms: continue
        visited_arms.add(a)
        out('            when d: %s' % a)
        out('                return factory.update_%s(n, %s)' % (snake(name), ', '.join(args)))
out('        node')
out('    }')
out(FACTORY_TAIL)

if report or problems:
    for p in problems: print(p)
    print('%d constructors, %d updaters, %d visits, %d clones; %d problems' % (len(news), len(updates), len(visits), len(clones), len(problems)))
if not report:
    open(OUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('wrote', OUT, len(lines), 'lines')
