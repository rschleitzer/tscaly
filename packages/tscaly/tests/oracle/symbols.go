// SPDX-License-Identifier: Apache-2.0
//
// symbols — the BINDER yardstick, and the fourth artifact of this suite.
//
// Dumps the reference's bind of one file. Five sections, in this order:
//
//	n <kind> <pos> <end> <sym|-> <locals|->       one line per node that has either
//	s <idx> <flags> <parent|-> <vdPos|-> <vdEnd|-> <members|-> <exports|-> <name>
//	d <idx> <kind> <pos> <end>                    one per declaration, in list order
//	x <idx> <exportSymIdx>                        the export symbol, when there is one
//	t <id> <count> / e <symIdx> <name>            one per table, entries name-sorted
//	f <symbolCount> <classifiableCount> / c <name>
//	B <pos> <end> <code>                          one per BIND diagnostic
//
// ★★★ WHY IT IS A SEPARATE ARTIFACT and not a section of the ast dump. The
// binder's output is not in the tree the parser yardstick walks: it hangs a
// SYMBOL off a declaration node, a LOCALS table off a container, and MEMBERS and
// EXPORTS tables off a symbol, and it appends to a diagnostic list of its own
// (SetBindDiagnostics, which neither Diagnostics() nor JSDiagnostics() includes).
// So the same argument the jsdoc yardstick rests on applies one phase later: with
// three artifacts, a port producing NO symbols and a port producing WRONG ones
// compare exactly equal, in both directions.
//
// ★★★ SYMBOL IDENTITY IS THE POINT, so the dump numbers symbols rather than
// describing them. A merged declaration — two `var x`, an interface reopened, a
// namespace and a function of one name — is ONE symbol with several
// declarations, and a port that made two symbols instead would produce the same
// SHAPE at every node. Indices are assigned in order of first encounter (the
// walk first, then whatever the emission of the symbol table reaches), which is
// deterministic on both sides and makes the merge visible as a repeated index.
//
// ★ The tables are SORTED BY NAME because the reference's SymbolTable is a Go
// map and its iteration order is deliberately random. That is a normalisation,
// and it is the one place this dump has: what it hides is an ORDER the reference
// does not have, and what it must not hide is a missing or extra entry, which is
// why the count is printed beside the table and the entries carry the symbol
// index they resolve to.
//
// ★ NAMES ARE ESCAPED, byte for byte: anything outside 0x21..0x7E becomes %XX.
// Two reasons, neither cosmetic — an internal symbol name begins with 0xFE (the
// reference's InternalSymbolNamePrefix, chosen because it cannot occur in
// identifier text), and a symbol's name can come from a string literal and
// therefore contain a space, which would otherwise split a field. The name is
// nevertheless printed LAST on every line it appears on, so a bug in the
// escaping cannot shift another field.
//
// ★ WHAT THIS FORMAT DOES NOT SHOW, stated because a format that hides a
// distinction hides every bug in that distinction:
//
//   - CheckFlags. Non-zero only in transient symbols the CHECKER creates, so
//     after a bind it is 0 on every symbol and comparing it would compare a
//     constant.
//   - The FLOW GRAPH. The binder builds one (FlowNodes on every reachable node,
//     labels, antecedents) and none of it is reachable through an exported
//     accessor — ast.FlowNode's fields are exported but the node's own flow
//     slot is not. It is the checker that reads it, so the yardstick that can
//     see it is the one after this.
//   - Node.Parent. MEASURED, not assumed: over the 12 444 files of the stage-2
//     corpus (1 467 387 nodes) and all 296 fixtures, every node's Parent is
//     exactly its parent in this walk and only the SourceFile's is nil. So a
//     parent column here would compare a constant. Parent is nevertheless
//     load-bearing for the binder, which reads it everywhere — it is observable
//     through THIS dump, as the symbol a declaration ends up in, and that is the
//     honest place to gate it.
//   - The diagnostic MESSAGE, its arguments and its related info. Code and span
//     only, exactly as the D and J sections of the ast dump.
//
// ★ THIS FILE IS OURS and lives in our repository, but it cannot be BUILT from
// here — every upstream package is under internal/, which Go admits only from
// inside the module rooted above it. The runner copies it into the submodule,
// builds, removes it again, and checks the submodule clean on both sides. See
// ../../TESTPLAN.md.
package main

import (
	"bufio"
	"fmt"
	"os"
	"slices"
	"strings"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/binder"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/tspath"
)

// ── identity registries ─────────────────────────────────────────────────────
//
// Both are assign-on-demand and both keep their assignment ORDER, because the
// order is what our side has to reproduce: a symbol index is only comparable if
// the two sides discover symbols in the same sequence.

type registry struct {
	symIndex   map[*ast.Symbol]int
	symOrder   []*ast.Symbol
	localIndex map[*ast.Node]int // locals tables, keyed by their container node
	tableCount int               // ONE id space for locals, members and exports
}

func newRegistry() *registry {
	return &registry{
		symIndex:   map[*ast.Symbol]int{},
		localIndex: map[*ast.Node]int{},
	}
}

func (r *registry) sym(s *ast.Symbol) int {
	if s == nil {
		return -1
	}
	if i, ok := r.symIndex[s]; ok {
		return i
	}
	i := len(r.symOrder)
	r.symIndex[s] = i
	r.symOrder = append(r.symOrder, s)
	return i
}

func (r *registry) locals(n *ast.Node) int {
	if i, ok := r.localIndex[n]; ok {
		return i
	}
	i := r.tableCount
	r.tableCount++
	r.localIndex[n] = i
	return i
}

func opt(i int) string {
	if i < 0 {
		return "-"
	}
	return fmt.Sprintf("%d", i)
}

// escape renders a symbol name so that it is one field and readable: every byte
// outside 0x21..0x7E, and `%` itself, becomes %XX. Byte-wise on purpose — a
// symbol name is a Go string, i.e. bytes, and the reference's internal names are
// not valid UTF-8 to begin with.
func escape(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < 0x21 || c > 0x7E || c == '%' {
			fmt.Fprintf(&b, "%%%02X", c)
		} else {
			b.WriteByte(c)
		}
	}
	if b.Len() == 0 {
		return "%00" // an empty name is a field too
	}
	return b.String()
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: symbols <file>")
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
	// The same three questions the ast oracle asks of the same argument, for the
	// same reasons: the NAME decides ambient-ness and the SCRIPT KIND, and both
	// change what is bound.
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

	r := newRegistry()
	membersTable := map[*ast.Symbol]int{}
	exportsTable := map[*ast.Symbol]int{}

	membersID := func(s *ast.Symbol) int {
		if s.Members == nil {
			return -1
		}
		if i, ok := membersTable[s]; ok {
			return i
		}
		i := r.tableCount
		r.tableCount++
		membersTable[s] = i
		return i
	}
	exportsID := func(s *ast.Symbol) int {
		if s.Exports == nil {
			return -1
		}
		if i, ok := exportsTable[s]; ok {
			return i
		}
		i := r.tableCount
		r.tableCount++
		exportsTable[s] = i
		return i
	}

	// ── section 1: the walk ─────────────────────────────────────────────────
	//
	// The same pre-order walk through the reference's own ForEachChild that the
	// parser yardstick compares, so a line here sits at a position the ast dump
	// has already agreed on — and only nodes that carry something are printed,
	// which is what keeps this artifact about the binder rather than about the
	// tree.
	type tableEntry struct {
		id      int
		entries ast.SymbolTable
	}
	var tables []tableEntry

	var walk func(n *ast.Node)
	walk = func(n *ast.Node) {
		symIdx := -1
		if s := n.Symbol(); s != nil {
			symIdx = r.sym(s)
		}
		localsIdx := -1
		if l := n.Locals(); l != nil {
			localsIdx = r.locals(n)
			tables = append(tables, tableEntry{localsIdx, l})
		}
		if symIdx >= 0 || localsIdx >= 0 {
			fmt.Fprintf(out, "n %d %d %d %s %s\n",
				int(n.Kind), n.Loc.Pos(), n.Loc.End(), opt(symIdx), opt(localsIdx))
		}
		n.ForEachChild(func(c *ast.Node) bool { walk(c); return false })
	}
	walk(sf.AsNode())

	// ★★★ EVERY LOCALS TABLE'S ENTRIES ARE NUMBERED NEXT, and leaving that out was
	// a real defect in the first draft of this oracle: a locals table can name a
	// symbol no walked node owns — `declareCommonJSVariable` makes two out of thin
	// air, and a namespace's locals hold symbols whose declaration the walk reaches
	// only through another container — so those symbols first got an index while
	// the `e` lines were being printed, i.e. AFTER the loop that emits `s` lines had
	// ended. The dump then referenced an index it never defined. Found by an
	// invariant check over the fixtures (24 of 296), not by reading the code, which
	// is the argument for having the check at all.
	for _, t := range tables {
		for _, name := range sortedNames(t.entries) {
			r.sym(t.entries[name])
		}
	}

	// ── section 2/3: the symbols and their declarations ─────────────────────
	//
	// The list GROWS while it is walked: a symbol's parent, its value
	// declaration's symbol and every entry of its tables may be a symbol the
	// walk never reached (the binder synthesizes some — `prototype` on a class
	// symbol has no declaration at all). Assigning indices on demand and
	// continuing to the end of the growing list is what makes the numbering
	// total, and the order deterministic.
	for i := 0; i < len(r.symOrder); i++ {
		s := r.symOrder[i]
		vdPos, vdEnd := -1, -1
		if s.ValueDeclaration != nil {
			vdPos, vdEnd = s.ValueDeclaration.Loc.Pos(), s.ValueDeclaration.Loc.End()
		}
		fmt.Fprintf(out, "s %d %d %s %s %s %s %s %s\n",
			i, int(s.Flags), opt(r.sym(s.Parent)),
			opt(vdPos), opt(vdEnd),
			opt(membersID(s)), opt(exportsID(s)),
			escape(s.Name))
		for _, d := range s.Declarations {
			fmt.Fprintf(out, "d %d %d %d %d\n", i, int(d.Kind), d.Loc.Pos(), d.Loc.End())
		}
		if s.ExportSymbol != nil {
			fmt.Fprintf(out, "x %d %d\n", i, r.sym(s.ExportSymbol))
		}
		if s.Members != nil {
			tables = append(tables, tableEntry{membersTable[s], s.Members})
		}
		if s.Exports != nil {
			tables = append(tables, tableEntry{exportsTable[s], s.Exports})
		}
		// Reaching every symbol a table names, so that the numbering above is
		// total before the tables are printed.
		for _, t := range []ast.SymbolTable{s.Members, s.Exports} {
			for _, name := range sortedNames(t) {
				r.sym(t[name])
			}
		}
	}

	// ── section 4: the tables ───────────────────────────────────────────────
	slices.SortStableFunc(tables, func(a, b tableEntry) int { return a.id - b.id })
	for _, t := range tables {
		fmt.Fprintf(out, "t %d %d\n", t.id, len(t.entries))
		for _, name := range sortedNames(t.entries) {
			fmt.Fprintf(out, "e %d %s\n", r.sym(t.entries[name]), escape(name))
		}
	}

	// ── section 5: the file totals and the bind diagnostics ─────────────────
	//
	// SymbolCount is the binder's own counter and NOT len(symbols): it counts
	// every symbol newSymbol ever made, including the ones a conflict threw
	// away, so it is a statement about the path taken and not about the result.
	fmt.Fprintf(out, "f %d %d\n", sf.SymbolCount, sf.ClassifiableNames.Len())
	var classifiable []string
	for name := range sf.ClassifiableNames.Keys() {
		classifiable = append(classifiable, name)
	}
	slices.Sort(classifiable)
	for _, name := range classifiable {
		fmt.Fprintf(out, "c %s\n", escape(name))
	}
	for _, d := range sf.BindDiagnostics() {
		fmt.Fprintf(out, "B %d %d %d\n", d.Pos(), d.End(), d.Code())
	}
}

func sortedNames(t ast.SymbolTable) []string {
	if t == nil {
		return nil
	}
	names := make([]string, 0, len(t))
	for name := range t {
		names = append(names, name)
	}
	slices.Sort(names)
	return names
}
