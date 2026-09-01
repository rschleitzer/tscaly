// SPDX-License-Identifier: Apache-2.0
//
// The reference half of the jsnum ARITHMETIC cross-check (slice 116).
//
// numcheck.go's twin, one half of the reference file over: that one measures the
// CONVERSION (FromString / String), this one measures the OPERATIONS — the five
// bitwise, the three shifts, the four arithmetic operators and the two the enum
// evaluator needs beside them (Remainder, Exponentiate). They are separate
// instruments because they are separate corpora: a conversion's input is a
// STRING and an operation's is a pair of doubles, and no generator produces both.
//
// One line of the corpus is two 16-hex-digit bit patterns. One line of output is
// thirteen results, in the fixed order below, each as sixteen hex digits — bits
// and never a rendering, so the comparison sees the NaN payload and the sign of
// a negative zero, neither of which a decimal text carries.
//
// ToInt32 and ToUint32 are not called directly: they are unexported upstream,
// and `BitwiseOR(x, 0)` and `UnsignedRightShift(x, 0)` are exactly them.
//
// Materialized into the submodule, built, removed — every oracle here does.
package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"

	"github.com/microsoft/typescript-go/internal/jsnum"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: arith <corpus>")
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
		f := strings.Fields(line)
		if len(f) != 2 {
			fmt.Fprintf(os.Stderr, "bad corpus line: %q\n", line)
			os.Exit(1)
		}
		ab, err1 := strconv.ParseUint(f[0], 16, 64)
		bb, err2 := strconv.ParseUint(f[1], 16, 64)
		if err1 != nil || err2 != nil {
			fmt.Fprintf(os.Stderr, "bad corpus line: %q\n", line)
			os.Exit(1)
		}
		x := jsnum.Number(math.Float64frombits(ab))
		y := jsnum.Number(math.Float64frombits(bb))
		r := []jsnum.Number{
			x + y,
			x - y,
			x * y,
			x / y,
			x.Remainder(y),
			x.Exponentiate(y),
			x.BitwiseOR(y),
			x.BitwiseAND(y),
			x.BitwiseXOR(y),
			x.LeftShift(y),
			x.SignedRightShift(y),
			x.UnsignedRightShift(y),
			x.BitwiseNOT(),
		}
		for i, v := range r {
			if i != 0 {
				out.WriteByte(' ')
			}
			fmt.Fprintf(out, "%016X", math.Float64bits(float64(v)))
		}
		out.WriteByte('\n')
	}
}
