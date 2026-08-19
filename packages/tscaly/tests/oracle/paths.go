// The reference half of the PATH cross-check (slice 28). Reads the same
// `<cwd>TAB<path>` corpus tscaly_paths reads and prints the same two fields, off
// the reference's own tspath.
//
// Materialized into the submodule, built, removed — the discipline every oracle
// here follows, because the submodule is also the corpus and a dirty one makes
// every comparison worthless.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/microsoft/typescript-go/internal/tspath"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: paths <corpus>")
		os.Exit(2)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	for _, line := range strings.Split(string(data), "\n") {
		if line == "" {
			continue
		}
		cwd, path, _ := strings.Cut(line, "\t")
		norm := tspath.GetNormalizedAbsolutePath(path, cwd)
		fmt.Fprintf(out, "%d %s\n", len(tspath.RemoveFileExtension(norm)), norm)
	}
}
