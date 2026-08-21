// SPDX-License-Identifier: Apache-2.0
//
// The reference half of the jsnum cross-check (slice 44). Reads the same
// one-input-string-per-line corpus tscaly_nums reads and prints the same two
// fields, off the reference's own jsnum.
//
// The bits are math.Float64bits of FromString's answer, so the comparison sees
// the NaN payload, the sign of a negative zero and the exact denormal — none of
// which the text carries.
//
// Materialized into the submodule, built, removed — the discipline every oracle
// here follows, because the submodule is also the corpus and a dirty one makes
// every comparison worthless.
package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
	"strings"

	"github.com/microsoft/typescript-go/internal/jsnum"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: nums <corpus>")
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	// The final newline terminates the last case rather than starting an empty
	// one; the EMPTY string is a case of its own here.
	text := strings.TrimSuffix(string(data), "\n")
	for _, line := range strings.Split(text, "\n") {
		n := jsnum.FromString(line)
		fmt.Fprintf(out, "%016X %s\n", math.Float64bits(float64(n)), n.String())
	}
}
