// SPDX-License-Identifier: Apache-2.0
//
// jsdoc — the THIRD yardstick.
//
// Dumps the reference's JSDoc parse of one file:
//
//	N <index> <count>                                 one line per node that has JSDoc
//	<depth> <kind> <pos> <end> <flags> <kindName>     one line per JSDoc node
//
// `index` is the node's position in the SAME pre-order walk the ast yardstick
// prints, so a JSDoc block is anchored to a node both sides have already agreed
// on. `count` is how many JSDoc comments hang on it — a node can carry several
// (`/** a */ /** b */ let x`), and a count without a tree would hide the case
// where one of them fails to parse.
//
// ★★★ WHY A THIRD YARDSTICK AND NOT A WIDER SECOND ONE. JSDoc nodes are NOT in
// the tree the ast yardstick walks. For a TS/TSX file the reference does not
// even parse them during ParseSourceFile — it sets HasLazyJSDoc and parses on
// the first access to Node.JSDoc(file) — and for a JS file it parses them into a
// side table (jsdocCache), reachable only through the same accessor. So a JSDoc
// defect is invisible to both existing yardsticks, in either direction: a port
// that produced no JSDoc at all and a port that produced a wrong tree compare
// exactly equal there. Folding this into ast.go would instead have turned all
// 804 units red at once the moment the section appeared, which is the opposite
// of what a slice-sized gate is for.
//
// ★★ WHAT THIS FORMAT DOES NOT SHOW, stated because a format that hides a
// distinction hides every bug in it:
//
//   - The JSDoc DIAGNOSTICS. The reference routes them to a separate list
//     (SetJSDocDiagnostics) and, for a TS file, the lazy parse throws them away
//     entirely — parseJSDocForNode runs on a fresh parser whose diagnostics
//     nobody reads. There is therefore nothing to compare on the majority of the
//     corpus, and comparing them on the JS minority would make the yardstick's
//     meaning depend on the file's extension. A JSDoc parse error is observable
//     here only through the SPANS it produces.
//   - A JSDocText's TEXT, a tag's comment text, and the name of an unknown tag.
//     Only kind, range and flags are compared, exactly as in the ast yardstick.
//     The text is not decoration — it drives `indent`, `margin` and the comment
//     accumulation, and therefore the spans that ARE compared — but it is
//     compared through its effect rather than directly.
//   - NodeList ranges, for the reason ast.go gives.
//
// ★ THIS FILE IS OURS and lives in our repository, but it cannot be BUILT from
// here — every upstream package is under internal/, which Go admits only from
// inside the module rooted above it. The runner copies it into the submodule,
// builds, removes it again, and checks the submodule clean on both sides.
package main

import (
	"fmt"
	"os"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/tspath"
)

func dump(out *os.File, n *ast.Node, depth int) {
	fmt.Fprintf(out, "%d %d %d %d %d %s\n",
		depth, int(n.Kind), n.Loc.Pos(), n.Loc.End(), int(n.Flags), n.Kind.String())
	n.ForEachChild(func(c *ast.Node) bool {
		dump(out, c, depth+1)
		return false
	})
}

// The SAME pre-order walk ast.go prints, so `index` names the same node on both
// sides. It is a counter rather than a span because two nodes can share a span
// (a VariableStatement and its declaration list often do) and an index cannot.
func walk(out *os.File, sf *ast.SourceFile, n *ast.Node, index *int) {
	i := *index
	*index++
	if jsdoc := n.JSDoc(sf); len(jsdoc) != 0 {
		fmt.Fprintf(out, "N %d %d\n", i, len(jsdoc))
		for _, d := range jsdoc {
			dump(out, d, 0)
		}
	}
	n.ForEachChild(func(c *ast.Node) bool {
		walk(out, sf, c, index)
		return false
	})
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: jsdoc <file>")
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
	fileName := tspath.GetNormalizedAbsolutePath(os.Args[1], cwd)

	// The same question ast.go asks, and for the same reasons — see its comment.
	// It matters here MORE than there: the kind decides whether the reference
	// parses JSDoc EAGERLY (JS, into the cache this dump reads) or lazily on
	// access (TS/TSX), and the accessor hides that difference, which is precisely
	// what makes one dumper serve both. Since slice 22 both paths are exercised.
	scriptKind := core.GetScriptKindFromFileName(fileName)

	opts := ast.SourceFileParseOptions{
		FileName: fileName,
		Path:     tspath.ToPath(fileName, cwd, true),
	}
	sf := parser.ParseSourceFile(opts, string(text), scriptKind)

	index := 0
	walk(os.Stdout, sf, sf.AsNode(), &index)
}
