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
        this.visit_embedded_statement(node)

    procedure visit_iteration_body_h(this, node: ref[AstNode]?) returns ref[AstNode]?
        this.visit_embedded_statement_h(node)

    procedure visit_function_body_h(this, node: ref[AstNode]?) returns ref[AstNode]?
        this.visit_node_h(node)

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
        this.visit_nodes_h(nodes)

    procedure visit_top_level_statements_h(this, nodes: ref[Array[ref[AstNode]?]]?) returns ref[Array[ref[AstNode]?]]?
        this.visit_nodes_h(nodes)

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
                    set (visited as ref[AstNode]).pos: 0 - 1
                    set (visited as ref[AstNode]).end: 0 - 1
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
                        set (last as ref[AstNode]).pos: 0 - 2
                        set (last as ref[AstNode]).end: 0 - 2
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

# clone is a method of the factory (generated below into the same define)
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
define HooksTagNone: int 0
define HooksTagEmitContext: int 1
define HooksTagDeepClone: int 2

define NodeVisitor
(
    host: ref[Page]
    factory: ref[NodeFactory]
    visit_tag: int
    hooks_tag: int
    synthetic_location: bool
)
{
    function create(host: ref[Page], factory: ref[NodeFactory], visit_tag: int, hooks_tag: int) returns ref[NodeVisitor]
        &NodeVisitor^host(host, factory, visit_tag, hooks_tag, false)

    ; VisitEachChild: the per-kind dispatch (generated).
    procedure visit_each_child(this, node: ref[AstNode]?) returns ref[AstNode]?
    {
        if node = null
            return null
        if visit_tag = VisitTagNone
            return node
        let n node as ref[AstNode]
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
