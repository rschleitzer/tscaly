// SPDX-License-Identifier: Apache-2.0
//
// tokens — the scanner yardstick.
//
// Dumps the reference's token stream for one file, one token per line:
//
//	<kind> <tokenStart> <tokenEnd> <tokenFlags> <kindName>
//
// The first four fields are what the runner compares. The fifth is there only so
// a failing diff is readable without our side having to carry a 351-entry name
// table; the runner strips it before comparing and shows it when reporting.
//
// ★ THIS FILE IS OURS, and it lives in our repository — but it cannot be BUILT
// from here. Every upstream package is under internal/, and Go admits those
// imports only from inside the module rooted above internal/, so no external
// module can import them (a separate module with a `replace` directive fails
// with "use of internal package ... not allowed"; a go.work workspace does not
// change that, because the rule is evaluated on module paths). The runner
// therefore copies this file into the submodule's tree, builds it there, and
// removes it again — and checks that the submodule is clean before and after.
// See ../../TESTPLAN.md.
package main

import (
	"fmt"
	"os"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/scanner"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: tokens <file.ts>")
		os.Exit(2)
	}

	text, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	s := scanner.NewScanner()
	s.SetText(string(text))

	out := os.Stdout
	for {
		tok := s.Scan()
		fmt.Fprintf(out, "%d %d %d %d %s\n",
			int(tok), s.TokenStart(), s.TokenEnd(), int(s.TokenFlags()), tok.String())
		if tok == ast.KindEndOfFile {
			break
		}
	}
}
