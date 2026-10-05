// SPDX-License-Identifier: Apache-2.0
//
// flow — the FLOW yardstick (slice 92).
//
// ★★★ WHY IT EXISTS, AND WHY THE SENTENCE IT REFUTES STOOD FOR SIXTY SLICES.
// binder.scaly's header says of the control flow graph: *"NONE of it is
// reachable through an exported accessor, so the symbols dump cannot see it and
// neither can any dump this suite has."* The first half is false and the second
// half followed from it. `Node.FlowNodeData()`, `BodyBase.EndFlowNode`,
// `SourceFile.EndFlowNode` and the four `ReturnFlowNode` slots are all EXPORTED
// — and an oracle in this directory is built INSIDE the reference's own module
// (that is the whole point of the copy-in), so `internal/ast` is as reachable
// to it as `internal/binder` already is. What was missing was not an accessor.
// It was a dump.
//
// The cost of believing it: the flow graph is the largest single mechanism this
// port does not have — `flow-graph 264` at 4 641 units and `flow-graph 79` at
// 1 542 head the stage-2 work list, with `check-property-access-expression`'s
// 3 504 waiting behind them — and the reason it was never opened is that a slice
// building it could not have been measured by anything. §3.5be forbids machinery
// no instrument can reach, so the missing instrument was the blocker and not the
// size.
//
// ── the four sections ────────────────────────────────────────────────────────
//
//	f <kind> <pos> <end> <flow> <endFlow> <returnFlow> <fallthroughFlow>
//	r <kind> <pos> <end> <flags>                         post-bind reachability
//	N <id> <flags> <nodeKind> <nodePos> <nodeEnd> <antecedent> <n> <a…>
//	w <id> <kind> <pos> <end> <clauseStart> <clauseEnd>  a switch-clause payload
//	l <id> <target> <n> <a…>                             a reduce-label payload
//
// A node is named by KIND, POS and END rather than by a walk index, exactly as
// the symbols dump names one: an index is a claim about the whole walk, and the
// walk is what the AST yardstick already compares.
//
// ★★★ SECTION `r` IS THE HALF A CHECKER CAN READ TODAY, and it is why the binder
// half of the flow dimension is a slice with a product rather than a prerequisite
// with none. `NodeFlagsUnreachable`, `HasImplicitReturn` and `HasExplicitReturn`
// are written by the BINDER and read by the CHECKER without ever touching the
// flow analyzer — TS7027 (unreachable code), TS7028 (unused label) and TS2378
// (a get accessor must return a value) are decided by those three bits alone. So
// the construction slice can be graded on diagnostics and not only on a graph.
//
// ★★ THE IDS ARE INTERNED IN ENCOUNTER ORDER AND THE ORDER IS THE MEASUREMENT.
// Section `f` walks the tree pre-order through ForEachChild and mints an id the
// first time a flow node is mentioned; section `N` then processes the id list in
// increasing order, minting ids for antecedents as it meets them. Both sides can
// reproduce that without agreeing on a hash, a pointer or a map iteration order —
// and a port that builds the right graph in the wrong ORDER prints different ids
// and says so, which is exactly the failure a set comparison would hide.
//
// ★★ WHAT IT DOES NOT SHOW. `FlowFlagsReferenced` and `FlowFlagsShared` are
// carried in the flags column, so the antecedent bookkeeping is compared; the
// ARENA the reference allocates from is not, and cannot be. A flow node nothing
// references is unreachable from both sections and is invisible on both sides —
// which is sound, because unreferenced is exactly what the reference's own
// consumer never sees.
//
// ★ THIS FILE IS OURS and cannot be BUILT from here; the runner copies it into
// the submodule, builds, removes it and checks the submodule clean on both
// sides.
package main

import (
	"bufio"
	"fmt"
	"os"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/binder"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/tspath"
)

// The three reachability bits the binder writes and the checker reads. Printed
// as a mask of their own rather than as the node's whole flags word: everything
// else in that word is the PARSER's, and the AST yardstick already compares it.
const reachabilityMask = ast.NodeFlagsUnreachable |
	ast.NodeFlagsHasImplicitReturn |
	ast.NodeFlagsHasExplicitReturn

type interner struct {
	id    map[*ast.FlowNode]int
	order []*ast.FlowNode
}

func newInterner() *interner {
	return &interner{id: map[*ast.FlowNode]int{}}
}

// -1 for the absent flow node, so that a column is always present and a missing
// one is never a shorter line.
func (r *interner) get(f *ast.FlowNode) int {
	if f == nil {
		return -1
	}
	if i, ok := r.id[f]; ok {
		return i
	}
	i := len(r.order)
	r.id[f] = i
	r.order = append(r.order, f)
	return i
}

func returnFlowNodeOf(n *ast.Node) *ast.FlowNode {
	switch n.Kind {
	case ast.KindConstructor:
		return n.AsConstructorDeclaration().ReturnFlowNode
	case ast.KindFunctionDeclaration:
		return n.AsFunctionDeclaration().ReturnFlowNode
	case ast.KindFunctionExpression:
		return n.AsFunctionExpression().ReturnFlowNode
	case ast.KindClassStaticBlockDeclaration:
		return n.AsClassStaticBlockDeclaration().ReturnFlowNode
	}
	return nil
}

// CaseOrDefaultClause.FallthroughFlowNode — the fourth per-node flow slot, and
// the only one that is not about how a node is REACHED: it is the flow a case
// clause hands to its successor when it falls through.
func fallthroughFlowNodeOf(n *ast.Node) *ast.FlowNode {
	switch n.Kind {
	case ast.KindCaseClause, ast.KindDefaultClause:
		return n.AsCaseOrDefaultClause().FallthroughFlowNode
	}
	return nil
}

func endFlowNodeOf(n *ast.Node) *ast.FlowNode {
	if n.Kind == ast.KindSourceFile {
		return n.AsSourceFile().EndFlowNode
	}
	if d := n.BodyData(); d != nil {
		return d.EndFlowNode
	}
	return nil
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: flow <file>")
		os.Exit(2)
	}
	text, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	// The same three questions the ast and symbols oracles ask of the same
	// argument, for the same reasons: the NAME decides ambient-ness and the
	// SCRIPT KIND, and both change what is bound — and therefore what flow
	// graph is built.
	fileName := tspath.GetNormalizedAbsolutePath(os.Args[1], cwd)
	scriptKind := core.GetScriptKindFromFileName(fileName)
	opts := ast.SourceFileParseOptions{
		FileName: fileName,
		Path:     tspath.ToPath(fileName, cwd, true),
	}
	sf := parser.ParseSourceFile(opts, string(text), scriptKind)
	binder.BindSourceFile(sf)

	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()

	r := newInterner()

	// ── section f/r: the walk ───────────────────────────────────────────────
	//
	// Pre-order through the reference's own ForEachChild, so a line here sits at
	// a position the AST yardstick has already agreed on. Only nodes that carry
	// something are printed — a tree of nodes with no flow is the AST dump's
	// subject, not this one's.
	type reach struct {
		kind     ast.Kind
		pos, end int
		flags    ast.NodeFlags
	}
	var reaches []reach

	var walk func(n *ast.Node)
	walk = func(n *ast.Node) {
		var flow *ast.FlowNode
		if d := n.FlowNodeData(); d != nil {
			flow = d.FlowNode
		}
		endFlow := endFlowNodeOf(n)
		retFlow := returnFlowNodeOf(n)
		ftFlow := fallthroughFlowNodeOf(n)
		if flow != nil || endFlow != nil || retFlow != nil || ftFlow != nil {
			fmt.Fprintf(out, "f %d %d %d %d %d %d %d\n",
				int(n.Kind), n.Loc.Pos(), n.Loc.End(),
				r.get(flow), r.get(endFlow), r.get(retFlow), r.get(ftFlow))
		}
		if f := n.Flags & reachabilityMask; f != 0 {
			reaches = append(reaches, reach{n.Kind, n.Loc.Pos(), n.Loc.End(), f})
		}
		n.ForEachChild(func(c *ast.Node) bool { walk(c); return false })
	}
	walk(sf.AsNode())

	// The reachability lines come out as a section of their own rather than as
	// two more columns on the `f` line, because the two sets of nodes barely
	// overlap: a node with a flow node usually has no reachability bit, and the
	// function-likes that carry HasImplicitReturn are not statements.
	for _, x := range reaches {
		fmt.Fprintf(out, "r %d %d %d %d\n", int(x.kind), x.pos, x.end, int(x.flags))
	}

	// ── section N: the flow nodes ───────────────────────────────────────────
	//
	// The list GROWS while it is walked — an antecedent may be a flow node no
	// node in the tree points at — which is the symbols oracle's own arrangement
	// and for the same reason: assigning ids on demand and continuing to the end
	// of the growing list is what makes the numbering total and the order
	// deterministic.
	type switchPayload struct {
		id                     int
		kind                   ast.Kind
		pos, end               int
		clauseStart, clauseEnd int
	}
	type reducePayload struct {
		id     int
		target int
		ids    []int
	}
	var switches []switchPayload
	var reduces []reducePayload

	for i := 0; i < len(r.order); i++ {
		f := r.order[i]
		nodeKind, nodePos, nodeEnd := -1, -1, -1
		if f.Node != nil {
			// ★★ THE TWO SYNTHETIC NODES ARE TOLD APART BY THE FLOW FLAGS AND NOT
			// BY THEIR TYPE, because `Node.data` is unexported: the two casts
			// `AsFlowSwitchClauseData` and `AsFlowReduceLabelData` are exported
			// and would panic on the wrong one. The flags are the reference's own
			// discriminator — createFlowSwitchClause is the only maker of the
			// first and createReduceLabel of the second — so asking them is the
			// same question, asked where the answer is public.
			switch {
			case f.Flags&ast.FlowFlagsSwitchClause != 0:
				// The synthetic node the reference builds so that a switch
				// clause RANGE can ride in the FlowNode.Node slot. It is not in
				// the tree, so it cannot be named by kind/pos/end and gets a
				// payload line of its own.
				d := f.Node.AsFlowSwitchClauseData()
				nodeKind = -2
				sw := switchPayload{id: i, clauseStart: int(d.ClauseStart), clauseEnd: int(d.ClauseEnd)}
				sw.kind, sw.pos, sw.end = d.SwitchStatement.Kind, d.SwitchStatement.Loc.Pos(), d.SwitchStatement.Loc.End()
				switches = append(switches, sw)
			case f.Flags&ast.FlowFlagsReduceLabel != 0:
				d := f.Node.AsFlowReduceLabelData()
				nodeKind = -3
				rp := reducePayload{id: i, target: r.get(d.Target)}
				for l := d.Antecedents; l != nil; l = l.Next {
					rp.ids = append(rp.ids, r.get(l.Flow))
				}
				reduces = append(reduces, rp)
			default:
				nodeKind, nodePos, nodeEnd = int(f.Node.Kind), f.Node.Loc.Pos(), f.Node.Loc.End()
			}
		}
		var ants []int
		for l := f.Antecedents; l != nil; l = l.Next {
			ants = append(ants, r.get(l.Flow))
		}
		fmt.Fprintf(out, "N %d %d %d %d %d %d %d",
			i, int(f.Flags), nodeKind, nodePos, nodeEnd, r.get(f.Antecedent), len(ants))
		for _, a := range ants {
			fmt.Fprintf(out, " %d", a)
		}
		fmt.Fprintln(out)
	}

	for _, s := range switches {
		fmt.Fprintf(out, "w %d %d %d %d %d %d\n",
			s.id, int(s.kind), s.pos, s.end, s.clauseStart, s.clauseEnd)
	}
	for _, p := range reduces {
		fmt.Fprintf(out, "l %d %d %d", p.id, p.target, len(p.ids))
		for _, a := range p.ids {
			fmt.Fprintf(out, " %d", a)
		}
		fmt.Fprintln(out)
	}
}
