// SPDX-License-Identifier: Apache-2.0
//
// ast — the parser yardstick.
//
// Dumps the reference's parse of one file. Two sections, in this order:
//
//	<depth> <kind> <pos> <end> <flags> <kindName>     one line per node
//	D <pos> <end> <code>                              one line per diagnostic
//
// The node lines are a pre-order walk through the reference's own ForEachChild,
// so the walk ORDER is part of what is compared — a port that visits a node's
// children in a different order is a different tree and says so here.
//
// `pos` is the FULL start (leading trivia included), `end` the token end, which
// is what core.TextRange carries. Getting that wrong is the classic silent
// parser defect, so it is compared rather than normalized away.
//
// The sixth field is the kind NAME, carried for readability only — the runner
// strips it before comparing, exactly as it does for the token dump, so our side
// need not carry a 386-entry name table.
//
// ★ WHAT THIS FORMAT DOES NOT SHOW, stated because a format that hides a
// distinction hides every bug in that distinction:
//
//   - NodeList ranges. A list (statements, parameters, members) carries its own
//     TextRange, and ForEachChild visits the list's ELEMENTS, never the list. Two
//     parses that disagree only about a list's extent compare equal here.
//   - Node.Parent. It is set by a later pass (`setParentFromContext`), not by
//     ParseSourceFile, so there is nothing to compare yet.
//   - The diagnostic MESSAGE. Only code and span are compared; the message text
//     lives in a 2000-entry table this port has no reason to carry yet. A wrong
//     message with a right code passes.
//
// ★ THIS FILE IS OURS and lives in our repository, but it cannot be BUILT from
// here — every upstream package is under internal/, which Go admits only from
// inside the module rooted above it. The runner copies it into the submodule,
// builds, removes it again, and checks the submodule clean on both sides. See
// ../../TESTPLAN.md.
package main

import (
	"fmt"
	"os"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/tspath"
)

func walk(out *os.File, n *ast.Node, depth int) {
	fmt.Fprintf(out, "%d %d %d %d %d %s\n",
		depth, int(n.Kind), n.Loc.Pos(), n.Loc.End(), int(n.Flags), n.Kind.String())
	n.ForEachChild(func(c *ast.Node) bool {
		walk(out, c, depth+1)
		return false
	})
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: ast <file>")
		os.Exit(2)
	}

	text, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// ★ The file NAME must be normalized and absolute — NewSourceFile panics
	// otherwise, and a relative path from the runner is exactly what it gets.
	// The normalization uses the reference's own tspath rather than
	// filepath.Abs, so the name the parser sees is the one the compiler would
	// have built.
	//
	// The name is not decoration: IsDeclarationFileName(".d.ts") sets
	// NodeFlagsAmbient on everything parsed, and since slice 14 our own dumper
	// takes the same path as its argument and asks the same question of it
	// (tscaly/tspath.scaly). 56 corpus units and five fixtures depend on the two
	// sides agreeing here.
	//
	// ★ The sentence that stood here — "the pinned corpus contains no .d.ts
	// case, so that path is unexercised on both sides" — was true of whole CASES
	// and false of the sections they split into, which is the same expiry
	// TESTPLAN.md records for its own version of it. A claim scoped to the unit
	// of measurement expires when the unit changes.
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fileName := tspath.GetNormalizedAbsolutePath(os.Args[1], cwd)

	// ★★★ The extension-derived kind, CLAMPED to the two kinds our port
	// implements — the reference's own GetScriptKindFromFileName, then TS for
	// anything that is not JSON. Both halves are deliberate.
	//
	// JSON must come through, because it is a different GRAMMAR (parseJSONText,
	// reached from ParseSourceFile before parseSourceFileWorker) with different
	// context flags and a different language variant. Comparing a .json unit as
	// TypeScript measured a document the reference never parses that way, which
	// is what split.go exists to say.
	//
	// Everything else is clamped to TS: .tsx and .jsx would select the JSX
	// language variant, which changes what `<` and `{` mean; .js would select
	// ScriptKindJS, where JSDoc is SYNTAX. Our port has neither grammar, so
	// asking for those kinds here would compare against a parse it cannot
	// produce — see classify_unit's .js arm for the measurement. Our side spells
	// the same two arms in Parser.supported_script_kind.
	scriptKind := core.GetScriptKindFromFileName(fileName)
	if scriptKind != core.ScriptKindJSON {
		scriptKind = core.ScriptKindTS
	}

	opts := ast.SourceFileParseOptions{
		FileName: fileName,
		Path:     tspath.ToPath(fileName, cwd, true),
	}
	sf := parser.ParseSourceFile(opts, string(text), scriptKind)

	out := os.Stdout
	walk(out, sf.AsNode(), 0)
	for _, d := range sf.Diagnostics() {
		fmt.Fprintf(out, "D %d %d %d\n", d.Pos(), d.End(), d.Code())
	}
}
