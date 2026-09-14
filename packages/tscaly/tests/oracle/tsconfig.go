// SPDX-License-Identifier: Apache-2.0
//
// The reference half of the TSCONFIG cross-check (slice 261). Reads a list of
// `<name>TAB<currentDirectory>TAB<bundle file>` lines — each bundle in the case
// yardstick's `==== TSCALY-FILE` format — and parses the bundle's tsconfig.json
// exactly as internal/testrunner/test_case_parser.go does, printing what
// `tscaly_dump --tsconfig=` prints: one `TSCONFIG-OPTION <name>\t<value>` line per
// set compiler option (struct order; the checker sorts) and one `TSCONFIG-FILE`
// line per root file name. An enum prints the first key of its map that names the
// value.
//
// Materialized into the submodule, built, removed — the discipline every oracle
// here follows.
package main

import (
	"bufio"
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/collections"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/testutil/harnessutil"
	"github.com/microsoft/typescript-go/internal/tsoptions"
	"github.com/microsoft/typescript-go/internal/tsoptions/tsoptionstest"
	"github.com/microsoft/typescript-go/internal/tspath"
)

type unit struct{ name, content string }

func readBundle(data string) []unit {
	var units []unit
	for len(data) > 0 {
		nl := strings.IndexByte(data, '\n')
		if nl < 0 {
			break
		}
		head := data[:nl]
		if strings.HasPrefix(head, "==== TSCALY-LINK ") {
			data = data[nl+1:]
			continue
		}
		rest := strings.TrimPrefix(head, "==== TSCALY-FILE ")
		f := strings.SplitN(rest, " ", 3)
		n, _ := strconv.Atoi(f[0])
		body := data[nl+1 : nl+1+n]
		units = append(units, unit{f[2], body})
		data = data[nl+1+n+1:]
	}
	return units
}

func render(v reflect.Value, name string) (string, bool) {
	switch x := v.Interface().(type) {
	case core.Tristate:
		if x == core.TSTrue {
			return "true", true
		}
		return "false", true
	case string:
		return x, true
	case []string:
		return strings.Join(x, ","), true
	case *int:
		return strconv.Itoa(*x), true
	case *collections.OrderedMap[string, []string]:
		keys := []string{}
		for k := range x.Keys() {
			keys = append(keys, k)
		}
		if len(keys) == 0 {
			return "{}", true
		}
		return strings.Join(keys, ","), true
	}
	opt := tsoptions.CommandLineCompilerOptionsMap.Get(name)
	if opt != nil && opt.EnumMap() != nil {
		for k, ev := range opt.EnumMap().Entries() {
			if reflect.ValueOf(ev).Int() == v.Int() {
				return k, true
			}
		}
	}
	return fmt.Sprintf("%v", v.Interface()), true
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: tsconfig <list>")
		os.Exit(2)
	}
	list, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	for _, line := range strings.Split(string(list), "\n") {
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, "\t", 3)
		fmt.Fprintf(out, "== %s\n", parts[0])
		data, err := os.ReadFile(parts[2])
		if err != nil {
			fmt.Fprintln(out, "READ-ERROR")
			continue
		}
		currentDirectory := parts[1]
		if currentDirectory == "" {
			currentDirectory = "/.src"
		} else {
			currentDirectory = tspath.GetNormalizedAbsolutePath(currentDirectory, "/.src")
		}
		units := readBundle(string(data))
		allFiles := map[string]string{}
		for _, u := range units {
			allFiles[tspath.GetNormalizedAbsolutePath(u.name, currentDirectory)] = u.content
		}
		host := tsoptionstest.NewVFSParseConfigHost(allFiles, currentDirectory, true)
		var parsed *tsoptions.ParsedCommandLine
		for _, u := range units {
			if harnessutil.GetConfigNameFromFileName(u.name) == "" {
				continue
			}
			configFileName := tspath.GetNormalizedAbsolutePath(u.name, currentDirectory)
			path := tspath.ToPath(u.name, host.GetCurrentDirectory(), host.Vfs.UseCaseSensitiveFileNames())
			configJson := parser.ParseSourceFile(ast.SourceFileParseOptions{FileName: configFileName, Path: path}, u.content, core.ScriptKindJSON)
			parsed = tsoptions.ParseJsonSourceFileConfigFileContent(&tsoptions.TsConfigSourceFile{SourceFile: configJson}, host, tspath.GetDirectoryPath(configFileName), nil, nil, configFileName, nil, nil, nil)
			break
		}
		if parsed == nil {
			fmt.Fprintln(out, "TSCONFIG-NONE")
			continue
		}
		o := reflect.ValueOf(parsed.ParsedConfig.CompilerOptions).Elem()
		t := o.Type()
		for i := range o.NumField() {
			f := o.Field(i)
			if !t.Field(i).IsExported() || f.IsZero() {
				continue
			}
			name, _, _ := strings.Cut(t.Field(i).Tag.Get("json"), ",")
			if name == "" || tsoptions.CommandLineCompilerOptionsMap.Get(name) == nil {
				continue
			}
			if s, ok := render(f, name); ok {
				fmt.Fprintf(out, "TSCONFIG-OPTION %s\t%s\n", name, s)
			}
		}
		for _, fn := range parsed.ParsedConfig.FileNames {
			fmt.Fprintf(out, "TSCONFIG-FILE %s\n", fn)
		}
	}
}
