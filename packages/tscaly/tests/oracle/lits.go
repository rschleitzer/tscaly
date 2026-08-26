// SPDX-License-Identifier: Apache-2.0
//
// The reference half of the LITERAL TYPE NAME cross-check (slice 71). Reads the
// same `<tag> <hex bytes>` corpus tscaly_lits reads and prints the same one
// composed name per line, off the reference's own printer and jsnum.
//
// ── Why these two functions are the reference for that name ─────────────────
//
// A string literal type is named by nodeBuilder building a synthetic
// StringLiteral with EFNoAsciiEscaping and the printer printing it. The node is
// synthesized, so canUseOriginalText is false and getLiteralText's StringLiteral
// arm runs: a double quote, escapeStringWorker with QuoteCharDoubleQuote and
// NeverAsciiEscape, a double quote. `printer.EscapeString` IS that call with
// those flags, so the composition below is the printer's own answer and not a
// re-derivation of it. (The one other flag the printer adds at this target,
// AllowNumericSeparator, is read by the NUMERIC arm only.)
//
// A bigint literal type is named `pseudoBigIntToString(value) + "n"`, and the
// value is `NewPseudoBigInt(ParsePseudoBigInt(text), false)` — the two jsnum
// routines the checker's arm calls, back to back.
//
// The third direction is the SCANNER's, and it is here rather than in the four
// yardsticks because none of them dumps a token's VALUE: `scanBigIntSuffix`
// appends the `n` and, for a binary or octal specifier, rewrites the digits
// through ParsePseudoBigInt, and slice 44 stood a raw source slice in for the
// whole of that. The separator is what makes the stand-in a defect rather than a
// difference — `1_000n` reaches the checker as `1_000n` and its digits come out
// `1_000` — so the fix needs an instrument and this is it.
//
// Materialized into the submodule, built, removed — the discipline every oracle
// here follows, because the submodule is also the corpus and a dirty one makes
// every comparison worthless.
package main

import (
	"bufio"
	"encoding/hex"
	"fmt"
	"os"
	"strings"

	"github.com/microsoft/typescript-go/internal/jsnum"
	"github.com/microsoft/typescript-go/internal/printer"
	"github.com/microsoft/typescript-go/internal/scanner"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: lits <corpus>")
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	text := strings.TrimSuffix(string(data), "\n")
	for _, line := range strings.Split(text, "\n") {
		if line == "" {
			continue
		}
		raw, err := hex.DecodeString(line[2:])
		if err != nil {
			fmt.Fprintln(out, "BAD")
			continue
		}
		s := string(raw)
		switch line[0] {
		case 'S':
			fmt.Fprintf(out, "\"%s\"\n", printer.EscapeString(s, printer.QuoteCharDoubleQuote))
		case 'B':
			writeBigInt(out, s)
		case 'T':
			sc := scanner.NewScanner()
			sc.SetText(s)
			k := sc.Scan()
			fmt.Fprintf(out, "%d %s\n", int(k), hex.EncodeToString([]byte(sc.TokenValue())))
		default:
			fmt.Fprintln(out, "BAD")
		}
	}
}

// ParsePseudoBigInt PANICS on a text big.Int refuses, and our side answers -1
// there — so the recover is what makes the two comparable rather than a way of
// surviving a bad corpus. Neither side can be reached with such a text by the
// scanner; the generator produces some anyway, because a panic that no input can
// cause is a claim, and one this instrument checks is a measurement.
func writeBigInt(out *bufio.Writer, s string) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintln(out, "PANIC")
		}
	}()
	v := jsnum.NewPseudoBigInt(jsnum.ParsePseudoBigInt(s), false)
	fmt.Fprintf(out, "%sn\n", v.String())
}
