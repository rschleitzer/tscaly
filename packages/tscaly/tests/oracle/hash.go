// SPDX-License-Identifier: Apache-2.0
//
// The reference half of the XXH3-64 cross-check (slice 289). Reads one input
// string per line and prints its 64-bit digest as sixteen lowercase hex digits,
// through the very package the reference's tracing uses for its thread ids.
//
// Built INSIDE the submodule (packages/tscaly/tests/hashcheck.sh copies it in
// and removes it again), because zeebo/xxh3 is the submodule's own dependency.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/zeebo/xxh3"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: oracle_hash <corpus>")
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	text := string(data)
	text = strings.TrimSuffix(text, "\n")
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	if text == "" {
		return
	}
	for _, line := range strings.Split(text, "\n") {
		h := xxh3.New()
		_, _ = h.WriteString(line)
		fmt.Fprintf(out, "%016x\n", h.Sum64())
	}
}
