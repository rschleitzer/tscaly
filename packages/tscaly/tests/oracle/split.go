// SPDX-License-Identifier: Apache-2.0
//
// split — the multi-file test case splitter, which is the REFERENCE's own.
//
// A corpus case under testdata/tests/cases is not one source file. It is a
// script for the reference's test harness: `// @option: value` lines configure
// the compile, and `// @Filename: path` starts a new file. 145 of the 296 cases
// at the pinned commit are multi-file, and the sections are not all TypeScript —
// package.json and tsconfig.json bodies, .js files, .d.ts files.
//
// ★★★ WHY THIS EXISTS, measured rather than assumed. Before it, the runner fed
// the whole case FILE to both parsers, so a tsconfig.json body was parsed as
// TypeScript. That is a document the reference's own test runner never parses,
// and it dominated what was left to port: of the 241 syntactic diagnostics the
// reference produced over the corpus, 209 (87 %) sat inside a .json section, and
// 213 of them were code 1005, `'{0}' expected`, flooding out of JSON read as TS.
// 25 of the 34 corpus cases blocked on diagnostics were blocked ONLY by that.
// The genuine error-recovery corpus is nine cases.
//
// So this is not a convenience. It makes the yardstick measure the documents the
// reference COMPILES instead of a concatenation nobody intends.
//
// ★★★ AND IT IS THE REFERENCE'S SPLITTER, NOT OURS. `ParseTestFilesAndSymlinks`
// is exported from internal/testrunner and is what the reference's own
// compiler_runner calls (through makeUnitsFromTest). Re-implementing the rule in
// bash or Python would put a second, guessing splitter beside the real one — the
// same argument that made the AST oracle right in the first place: compare
// against the reference's own output, never against a reading of it. The unit
// text is therefore NOT a byte-slice of the case file: the splitter drops the
// `// @option:` lines, drops leading blank lines, and normalizes CRLF. Every
// span moves. That is the point — those are the bytes the reference parses.
//
// A single-file case yields exactly ONE unit, named after the base file name,
// with the whole text as its content (`test_case_parser.go`'s tail does this
// explicitly). So this generalizes the old behaviour rather than replacing it,
// which is why the 151 single-file corpus cases and all of our own fixtures keep
// their case keys.
//
// Usage:  split <case.ts> <outdir>
//
// Writes one file per unit into <outdir> and prints one manifest line per unit
// to stdout:
//
//	<index> <written-file> <original-unit-name>
//
// The written name carries the unit's own BASENAME, so its extension survives —
// the runner classifies on it, and the ast oracle reads `.d.ts` off it to set
// NodeFlagsAmbient. The `uNN_` prefix is there because two sections of one case
// can have the same basename under different directories.
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
	"path/filepath"

	"github.com/microsoft/typescript-go/internal/testrunner"
)

type unit struct {
	name    string
	content string
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintln(os.Stderr, "usage: split <case.ts> <outdir>")
		os.Exit(2)
	}
	casePath, outDir := os.Args[1], os.Args[2]

	text, err := os.ReadFile(casePath)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// ★ The splitter PANICS on a case with non-comment content before the first
	// `// @Filename` directive. That is a statement about the corpus, not about
	// us, so it is caught and named rather than surfacing as a Go stack trace
	// that reads like a broken oracle.
	var units []*unit
	func() {
		defer func() {
			if r := recover(); r != nil {
				fmt.Fprintf(os.Stderr, "the reference's splitter rejected this case: %v\n", r)
				os.Exit(3)
			}
		}()
		units, _, _, _, err = testrunner.ParseTestFilesAndSymlinks(
			string(text),
			filepath.Base(casePath),
			func(name string, content string, fileOptions map[string]string) (*unit, error) {
				return &unit{name: name, content: content}, nil
			},
		)
	}()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if err := os.MkdirAll(outDir, 0o755); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	for i, u := range units {
		written := filepath.Join(outDir, fmt.Sprintf("u%02d_%s", i, filepath.Base(u.name)))
		if err := os.WriteFile(written, []byte(u.content), 0o644); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		fmt.Printf("%d %s %s\n", i, written, u.name)
	}
}
