// SPDX-License-Identifier: Apache-2.0
//
// batch — ALL EIGHT ORACLES IN ONE PROCESS, over a whole corpus, in one stream.
//
// ★★★ WHY IT EXISTS (2026-09-02). The runner used to spawn the split oracle once per
// case and six dump oracles once per unit, and write every answer to its own file:
// a stage-2 run was ~130 000 process starts and 443 000 files, and the box's
// endpoint protection scanned every one of them.
// This program reads `<case file>\t<case name>` lines on stdin, splits each case
// with the reference's own splitter, dumps every unit's seven artifacts in-process
// with a worker pool, and writes ONE framed stream to stdout. No file is created.
//
// ★★★ WHAT IS MEASURED IS UNCHANGED, and that is checked rather than argued: every
// artifact body is produced by the same code as the standalone oracle it replaces
// (transcribed function for function below — tokens.go, ast.go, jsdoc.go,
// symbols.go, flow.go, types.go, split.go are kept in this directory as the
// readable single-file forms), with the same file name handed to the parser: the
// path the unit WOULD have had on disk, so ScriptKind and the `.d.ts` flag come
// out identical. A unit is checked in its OWN program with its OWN parse of the
// lib, exactly as before; nothing is shared between units except the lib's bytes.
// Measured on landing: byte-identical to the seven standalone oracles over the
// whole stage-1 tree.
//
// ★★★ THE REFERENCE HAS PROCESS-WIDE STATE, AND IT IS IN THE OUTPUT. `ast.GetNodeId`
// and `ast.GetSymbolId` draw from two package-level atomic counters, and the symbol
// id is the middle of a private member's symbol NAME (`__#<id>@name`, binder.go's
// GetSymbolNameForPrivateIdentifier), so a second unit in the same process gets
// different names than a fresh process would — measured: 24 symbols artifacts, all
// of them private-name fixtures, on the first batch run. Both counters are reset
// to zero before every artifact (a `go:linkname` pull, since they are unexported),
// which is exactly the state a fresh oracle process started with — and it is why
// this program is SEQUENTIAL: a shared counter cannot be reset per goroutine.
// Parallelism is the caller's, by running several batches over disjoint case lists.
//
// ★★ A PANIC IS PER ARTIFACT AND PER UNIT, never per run. Each dump runs under
// `recover`; a panic answers rc 3 with the message in the err field, which is the
// standalone oracles' exit-3 contract, and the next artifact and the next unit
// proceed. The splitter's rejection is rc 3 on the case, as before.
//
// Framing (every count is a byte count; bodies are raw and end with "\n" added
// here, so an empty body is exactly one newline):
//
//	==== TSCALY-CASE <name>\t<case file>
//	==== TSCALY-SPLIT <rc> <errbytes>\n<err>\n            rc 0 ok, 1 unreadable, 3 rejected
//	==== TSCALY-UNIT <idx> <bytes>\t<unit name>\t<path>\n<content>\n
//	==== TSCALY-REF <artifact> <rc> <outbytes> <errbytes>\n<out>\n<err>\n   × tokens ast jsdoc symbols flow types emit
//
// Usage:  batch <out dir>  < cases.tsv       (out dir only names the units' paths)
package main

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync/atomic"
	_ "unsafe"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/binder"
	"github.com/microsoft/typescript-go/internal/bundled"
	"github.com/microsoft/typescript-go/internal/checker"
	"github.com/microsoft/typescript-go/internal/compiler"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/module"
	"github.com/microsoft/typescript-go/internal/packagejson"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/scanner"
	"github.com/microsoft/typescript-go/internal/symlinks"
	"github.com/microsoft/typescript-go/internal/testrunner"
	"github.com/microsoft/typescript-go/internal/tsoptions"
	"github.com/microsoft/typescript-go/internal/tspath"
	"github.com/microsoft/typescript-go/internal/vfs/osvfs"
	"github.com/microsoft/typescript-go/internal/vfs/vfstest"
)

// ───────────────────────── tokens.go ─────────────────────────

func dumpTokens(out *bytes.Buffer, fileName string, text string) {
	variant := core.LanguageVariantStandard
	switch core.GetScriptKindFromFileName(fileName) {
	case core.ScriptKindJSON, core.ScriptKindTSX, core.ScriptKindJSX, core.ScriptKindJS:
		variant = core.LanguageVariantJSX
	}
	s := scanner.NewScanner()
	s.SetText(text)
	s.SetLanguageVariant(variant)
	for {
		tok := s.Scan()
		fmt.Fprintf(out, "%d %d %d %d %s\n",
			int(tok), s.TokenStart(), s.TokenEnd(), int(s.TokenFlags()), tok.String())
		if tok == ast.KindEndOfFile {
			break
		}
	}
}

// ───────────────────────── the parse every tree oracle starts from ─────────────────────────

func parseUnit(fileName string, cwd string, text string) *ast.SourceFile {
	fn := tspath.GetNormalizedAbsolutePath(fileName, cwd)
	scriptKind := core.GetScriptKindFromFileName(fn)
	opts := ast.SourceFileParseOptions{
		FileName: fn,
		Path:     tspath.ToPath(fn, cwd, true),
	}
	return parser.ParseSourceFile(opts, text, scriptKind)
}

// ───────────────────────── ast.go ─────────────────────────

func astWalk(out *bytes.Buffer, n *ast.Node, depth int) {
	fmt.Fprintf(out, "%d %d %d %d %d %s\n",
		depth, int(n.Kind), n.Loc.Pos(), n.Loc.End(), int(n.Flags), n.Kind.String())
	n.ForEachChild(func(c *ast.Node) bool {
		astWalk(out, c, depth+1)
		return false
	})
}

func dumpAst(out *bytes.Buffer, fileName string, cwd string, text string) {
	sf := parseUnit(fileName, cwd, text)
	astWalk(out, sf.AsNode(), 0)
	for _, d := range sf.Diagnostics() {
		fmt.Fprintf(out, "D %d %d %d\n", d.Pos(), d.End(), d.Code())
	}
	for _, d := range sf.JSDiagnostics() {
		fmt.Fprintf(out, "J %d %d %d\n", d.Pos(), d.End(), d.Code())
	}
}

// ───────────────────────── jsdoc.go ─────────────────────────

func jsdocDump(out *bytes.Buffer, n *ast.Node, depth int) {
	fmt.Fprintf(out, "%d %d %d %d %d %s\n",
		depth, int(n.Kind), n.Loc.Pos(), n.Loc.End(), int(n.Flags), n.Kind.String())
	n.ForEachChild(func(c *ast.Node) bool {
		jsdocDump(out, c, depth+1)
		return false
	})
}

func jsdocWalk(out *bytes.Buffer, sf *ast.SourceFile, n *ast.Node, index *int) {
	i := *index
	*index++
	if jsdoc := n.JSDoc(sf); len(jsdoc) != 0 {
		fmt.Fprintf(out, "N %d %d\n", i, len(jsdoc))
		for _, d := range jsdoc {
			jsdocDump(out, d, 0)
		}
	}
	n.ForEachChild(func(c *ast.Node) bool {
		jsdocWalk(out, sf, c, index)
		return false
	})
}

func dumpJsdoc(out *bytes.Buffer, fileName string, cwd string, text string) {
	sf := parseUnit(fileName, cwd, text)
	index := 0
	jsdocWalk(out, sf, sf.AsNode(), &index)
}

// ───────────────────────── symbols.go ─────────────────────────

type registry struct {
	symIndex   map[*ast.Symbol]int
	symOrder   []*ast.Symbol
	localIndex map[*ast.Node]int
	tableCount int
}

func newRegistry() *registry {
	return &registry{
		symIndex:   map[*ast.Symbol]int{},
		localIndex: map[*ast.Node]int{},
	}
}

func (r *registry) sym(s *ast.Symbol) int {
	if s == nil {
		return -1
	}
	if i, ok := r.symIndex[s]; ok {
		return i
	}
	i := len(r.symOrder)
	r.symIndex[s] = i
	r.symOrder = append(r.symOrder, s)
	return i
}

func (r *registry) locals(n *ast.Node) int {
	if i, ok := r.localIndex[n]; ok {
		return i
	}
	i := r.tableCount
	r.tableCount++
	r.localIndex[n] = i
	return i
}

func opt(i int) string {
	if i < 0 {
		return "-"
	}
	return fmt.Sprintf("%d", i)
}

func symEscape(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < 0x21 || c > 0x7E || c == '%' {
			fmt.Fprintf(&b, "%%%02X", c)
		} else {
			b.WriteByte(c)
		}
	}
	if b.Len() == 0 {
		return "%00"
	}
	return b.String()
}

func sortedNames(t ast.SymbolTable) []string {
	if t == nil {
		return nil
	}
	names := make([]string, 0, len(t))
	for name := range t {
		names = append(names, name)
	}
	slices.Sort(names)
	return names
}

func dumpSymbols(out *bytes.Buffer, fileName string, cwd string, text string) {
	sf := parseUnit(fileName, cwd, text)
	binder.BindSourceFile(sf)
	r := newRegistry()
	membersTable := map[*ast.Symbol]int{}
	exportsTable := map[*ast.Symbol]int{}
	membersID := func(s *ast.Symbol) int {
		if s.Members == nil {
			return -1
		}
		if i, ok := membersTable[s]; ok {
			return i
		}
		i := r.tableCount
		r.tableCount++
		membersTable[s] = i
		return i
	}
	exportsID := func(s *ast.Symbol) int {
		if s.Exports == nil {
			return -1
		}
		if i, ok := exportsTable[s]; ok {
			return i
		}
		i := r.tableCount
		r.tableCount++
		exportsTable[s] = i
		return i
	}
	type tableEntry struct {
		id      int
		entries ast.SymbolTable
	}
	var tables []tableEntry
	var walk func(n *ast.Node)
	walk = func(n *ast.Node) {
		symIdx := -1
		if s := n.Symbol(); s != nil {
			symIdx = r.sym(s)
		}
		localsIdx := -1
		if l := n.Locals(); l != nil {
			localsIdx = r.locals(n)
			tables = append(tables, tableEntry{localsIdx, l})
		}
		if symIdx >= 0 || localsIdx >= 0 {
			fmt.Fprintf(out, "n %d %d %d %s %s\n",
				int(n.Kind), n.Loc.Pos(), n.Loc.End(), opt(symIdx), opt(localsIdx))
		}
		n.ForEachChild(func(c *ast.Node) bool { walk(c); return false })
	}
	walk(sf.AsNode())
	for _, t := range tables {
		for _, name := range sortedNames(t.entries) {
			r.sym(t.entries[name])
		}
	}
	for i := 0; i < len(r.symOrder); i++ {
		s := r.symOrder[i]
		vdPos, vdEnd := -1, -1
		if s.ValueDeclaration != nil {
			vdPos, vdEnd = s.ValueDeclaration.Loc.Pos(), s.ValueDeclaration.Loc.End()
		}
		fmt.Fprintf(out, "s %d %d %s %s %s %s %s %s\n",
			i, int(s.Flags), opt(r.sym(s.Parent)),
			opt(vdPos), opt(vdEnd),
			opt(membersID(s)), opt(exportsID(s)),
			symEscape(s.Name))
		for _, d := range s.Declarations {
			fmt.Fprintf(out, "d %d %d %d %d\n", i, int(d.Kind), d.Loc.Pos(), d.Loc.End())
		}
		if s.ExportSymbol != nil {
			fmt.Fprintf(out, "x %d %d\n", i, r.sym(s.ExportSymbol))
		}
		if s.Members != nil {
			tables = append(tables, tableEntry{membersTable[s], s.Members})
		}
		if s.Exports != nil {
			tables = append(tables, tableEntry{exportsTable[s], s.Exports})
		}
		for _, t := range []ast.SymbolTable{s.Members, s.Exports} {
			for _, name := range sortedNames(t) {
				r.sym(t[name])
			}
		}
	}
	slices.SortStableFunc(tables, func(a, b tableEntry) int { return a.id - b.id })
	for _, t := range tables {
		fmt.Fprintf(out, "t %d %d\n", t.id, len(t.entries))
		for _, name := range sortedNames(t.entries) {
			fmt.Fprintf(out, "e %d %s\n", r.sym(t.entries[name]), symEscape(name))
		}
	}
	fmt.Fprintf(out, "f %d %d\n", sf.SymbolCount, sf.ClassifiableNames.Len())
	var classifiable []string
	for name := range sf.ClassifiableNames.Keys() {
		classifiable = append(classifiable, name)
	}
	slices.Sort(classifiable)
	for _, name := range classifiable {
		fmt.Fprintf(out, "c %s\n", symEscape(name))
	}
	for _, d := range sf.BindDiagnostics() {
		fmt.Fprintf(out, "B %d %d %d\n", d.Pos(), d.End(), d.Code())
	}
}

// ───────────────────────── flow.go ─────────────────────────

const reachabilityMask = ast.NodeFlagsUnreachable |
	ast.NodeFlagsHasImplicitReturn |
	ast.NodeFlagsHasExplicitReturn

type interner struct {
	id    map[*ast.FlowNode]int
	order []*ast.FlowNode
}

func newInterner() *interner {
	return &interner{id: map[*ast.FlowNode]int{}}
}

func (r *interner) get(f *ast.FlowNode) int {
	if f == nil {
		return -1
	}
	if i, ok := r.id[f]; ok {
		return i
	}
	i := len(r.order)
	r.id[f] = i
	r.order = append(r.order, f)
	return i
}

func returnFlowNodeOf(n *ast.Node) *ast.FlowNode {
	switch n.Kind {
	case ast.KindConstructor:
		return n.AsConstructorDeclaration().ReturnFlowNode
	case ast.KindFunctionDeclaration:
		return n.AsFunctionDeclaration().ReturnFlowNode
	case ast.KindFunctionExpression:
		return n.AsFunctionExpression().ReturnFlowNode
	case ast.KindClassStaticBlockDeclaration:
		return n.AsClassStaticBlockDeclaration().ReturnFlowNode
	}
	return nil
}

func fallthroughFlowNodeOf(n *ast.Node) *ast.FlowNode {
	switch n.Kind {
	case ast.KindCaseClause, ast.KindDefaultClause:
		return n.AsCaseOrDefaultClause().FallthroughFlowNode
	}
	return nil
}

func endFlowNodeOf(n *ast.Node) *ast.FlowNode {
	if n.Kind == ast.KindSourceFile {
		return n.AsSourceFile().EndFlowNode
	}
	if d := n.BodyData(); d != nil {
		return d.EndFlowNode
	}
	return nil
}

func dumpFlow(out *bytes.Buffer, fileName string, cwd string, text string) {
	sf := parseUnit(fileName, cwd, text)
	binder.BindSourceFile(sf)
	r := newInterner()
	type reach struct {
		kind     ast.Kind
		pos, end int
		flags    ast.NodeFlags
	}
	var reaches []reach
	var walk func(n *ast.Node)
	walk = func(n *ast.Node) {
		var flow *ast.FlowNode
		if d := n.FlowNodeData(); d != nil {
			flow = d.FlowNode
		}
		endFlow := endFlowNodeOf(n)
		retFlow := returnFlowNodeOf(n)
		ftFlow := fallthroughFlowNodeOf(n)
		if flow != nil || endFlow != nil || retFlow != nil || ftFlow != nil {
			fmt.Fprintf(out, "f %d %d %d %d %d %d %d\n",
				int(n.Kind), n.Loc.Pos(), n.Loc.End(),
				r.get(flow), r.get(endFlow), r.get(retFlow), r.get(ftFlow))
		}
		if f := n.Flags & reachabilityMask; f != 0 {
			reaches = append(reaches, reach{n.Kind, n.Loc.Pos(), n.Loc.End(), f})
		}
		n.ForEachChild(func(c *ast.Node) bool { walk(c); return false })
	}
	walk(sf.AsNode())
	for _, x := range reaches {
		fmt.Fprintf(out, "r %d %d %d %d\n", int(x.kind), x.pos, x.end, int(x.flags))
	}
	type switchPayload struct {
		id                     int
		kind                   ast.Kind
		pos, end               int
		clauseStart, clauseEnd int
	}
	type reducePayload struct {
		id     int
		target int
		ids    []int
	}
	var switches []switchPayload
	var reduces []reducePayload
	for i := 0; i < len(r.order); i++ {
		f := r.order[i]
		nodeKind, nodePos, nodeEnd := -1, -1, -1
		if f.Node != nil {
			switch {
			case f.Flags&ast.FlowFlagsSwitchClause != 0:
				d := f.Node.AsFlowSwitchClauseData()
				nodeKind = -2
				sw := switchPayload{id: i, clauseStart: int(d.ClauseStart), clauseEnd: int(d.ClauseEnd)}
				sw.kind, sw.pos, sw.end = d.SwitchStatement.Kind, d.SwitchStatement.Loc.Pos(), d.SwitchStatement.Loc.End()
				switches = append(switches, sw)
			case f.Flags&ast.FlowFlagsReduceLabel != 0:
				d := f.Node.AsFlowReduceLabelData()
				nodeKind = -3
				rp := reducePayload{id: i, target: r.get(d.Target)}
				for l := d.Antecedents; l != nil; l = l.Next {
					rp.ids = append(rp.ids, r.get(l.Flow))
				}
				reduces = append(reduces, rp)
			default:
				nodeKind, nodePos, nodeEnd = int(f.Node.Kind), f.Node.Loc.Pos(), f.Node.Loc.End()
			}
		}
		var ants []int
		for l := f.Antecedents; l != nil; l = l.Next {
			ants = append(ants, r.get(l.Flow))
		}
		fmt.Fprintf(out, "N %d %d %d %d %d %d %d",
			i, int(f.Flags), nodeKind, nodePos, nodeEnd, r.get(f.Antecedent), len(ants))
		for _, a := range ants {
			fmt.Fprintf(out, " %d", a)
		}
		fmt.Fprintln(out)
	}
	for _, s := range switches {
		fmt.Fprintf(out, "w %d %d %d %d %d %d\n",
			s.id, int(s.kind), s.pos, s.end, s.clauseStart, s.clauseEnd)
	}
	for _, p := range reduces {
		fmt.Fprintf(out, "l %d %d %d", p.id, p.target, len(p.ids))
		for _, a := range p.ids {
			fmt.Fprintf(out, " %d", a)
		}
		fmt.Fprintln(out)
	}
}

// ───────────────────────── types.go ─────────────────────────

var libFiles = []string{"lib.es5.d.ts"}

type prog struct {
	files  []*ast.SourceFile
	byName map[string]*ast.SourceFile
	libs   map[tspath.Path]bool
	cwd    string
	opts   *core.CompilerOptions
}

func (p *prog) Options() *core.CompilerOptions { return p.opts }
func (p *prog) SourceFiles() []*ast.SourceFile { return p.files }
func (p *prog) BindSourceFiles() {
	for _, f := range p.files {
		if !f.IsBound() {
			binder.BindSourceFile(f)
		}
	}
}
func (p *prog) FileExists(fileName string) bool                                  { return p.byName[fileName] != nil }
func (p *prog) GetSourceFile(fileName string) *ast.SourceFile                    { return p.byName[fileName] }
func (p *prog) UseCaseSensitiveFileNames() bool                                  { return true }
func (p *prog) GetCurrentDirectory() string                                      { return p.cwd }
func (p *prog) CommonSourceDirectory() string                                    { return "" }
func (p *prog) GetGlobalTypingsCacheLocation() string                            { return "" }
func (p *prog) GetSymlinkCache() *symlinks.KnownSymlinks                         { return nil }
func (p *prog) GetRedirectTargets(path tspath.Path) []string                     { return nil }
func (p *prog) GetPackagesMap() map[string]bool                                  { return nil }
func (p *prog) GetNearestAncestorDirectoryWithPackageJson(dirname string) string { return "" }
func (p *prog) GetSourceFileForResolvedModule(fileName string) *ast.SourceFile {
	return p.byName[fileName]
}
func (p *prog) IsSourceFileDefaultLibrary(path tspath.Path) bool                        { return p.libs[path] }
func (p *prog) GetSourceOfProjectReferenceIfOutputIncluded(file ast.HasFileName) string { return "" }
func (p *prog) GetProjectReferenceFromSource(path tspath.Path) *tsoptions.SourceOutputAndProjectReference {
	return nil
}
func (p *prog) GetProjectReferenceFromOutputDts(path tspath.Path) *tsoptions.SourceOutputAndProjectReference {
	return nil
}
func (p *prog) GetRedirectForResolution(file ast.HasFileName) *tsoptions.ParsedCommandLine {
	return nil
}
func (p *prog) GetPackageJsonInfo(pkgJsonPath string) *packagejson.InfoCacheEntry { return nil }
func (p *prog) GetSourceFileMetaData(path tspath.Path) ast.SourceFileMetaData {
	return ast.SourceFileMetaData{}
}
func (p *prog) GetJSXRuntimeImportSpecifier(path tspath.Path) (string, *ast.Node) { return "", nil }
func (p *prog) GetImportHelpersImportSpecifier(path tspath.Path) *ast.Node        { return nil }
func (p *prog) SourceFileMayBeEmitted(sourceFile *ast.SourceFile, forceDtsEmit bool) bool {
	return false
}
func (p *prog) GetDefaultResolutionModeForFile(file ast.HasFileName) core.ResolutionMode {
	return core.ResolutionModeNone
}
func (p *prog) GetEmitModuleFormatOfFile(sourceFile ast.HasFileName) core.ModuleKind {
	return core.ModuleKindNone
}
func (p *prog) GetImpliedNodeFormatForEmit(sourceFile ast.HasFileName) core.ModuleKind {
	return core.ModuleKindNone
}
func (p *prog) GetEmitSyntaxForUsageLocation(sourceFile ast.HasFileName, usageLocation *ast.StringLiteralLike) core.ResolutionMode {
	return core.ResolutionModeNone
}
func (p *prog) GetModeForUsageLocation(file ast.HasFileName, moduleSpecifier *ast.StringLiteralLike) core.ResolutionMode {
	return core.ResolutionModeNone
}
func (p *prog) GetResolvedModule(currentSourceFile ast.HasFileName, moduleReference string, mode core.ResolutionMode) *module.ResolvedModule {
	return nil
}
func (p *prog) GetResolvedModuleFromModuleSpecifier(file ast.HasFileName, moduleSpecifier *ast.StringLiteralLike) *module.ResolvedModule {
	return nil
}
func (p *prog) GetResolvedModules() map[tspath.Path]module.ModeAwareCache[*module.ResolvedModule] {
	return nil
}

func forEachASTNode(node *ast.Node) []*ast.Node {
	var result []*ast.Node
	work := []*ast.Node{node}
	var resChildren []*ast.Node
	addChild := func(child *ast.Node) bool {
		resChildren = append(resChildren, child)
		return false
	}
	for len(work) > 0 {
		elem := work[len(work)-1]
		work = work[:len(work)-1]
		if elem.Flags&ast.NodeFlagsReparsed == 0 || elem.Kind == ast.KindAsExpression || elem.Kind == ast.KindSatisfiesExpression ||
			((elem.Parent.Kind == ast.KindSatisfiesExpression || elem.Parent.Kind == ast.KindAsExpression) && elem == elem.Parent.Expression()) {
			if elem.Flags&ast.NodeFlagsReparsed == 0 || elem.Parent.Kind == ast.KindAsExpression || elem.Parent.Kind == ast.KindSatisfiesExpression {
				result = append(result, elem)
			}
			elem.ForEachChild(addChild)
			slices.Reverse(resChildren)
			work = append(work, resChildren...)
			resChildren = resChildren[:0]
		}
	}
	return result
}

func skipForType(node *ast.Node) bool {
	if ast.IsPartOfTypeNode(node) {
		return true
	}
	if (node.Kind == ast.KindAsExpression || node.Kind == ast.KindSatisfiesExpression) &&
		node.Type().Flags&ast.NodeFlagsReparsed != 0 {
		return true
	}
	if ast.IsIdentifier(node) &&
		(ast.GetMeaningFromDeclaration(node.Parent)&ast.SemanticMeaningValue) == 0 &&
		!(ast.IsTypeOrJSTypeAliasDeclaration(node.Parent) && node == node.Parent.Name()) {
		return true
	}
	return ast.IsOmittedExpression(node)
}

func typeEscape(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "\\r")
	return strings.ReplaceAll(s, "\t", "\\t")
}

func isNamelessTypeOnlyImportClause(node *ast.Node) bool {
	return node.Kind == ast.KindImportClause && node.IsTypeOnly() && node.Name() == nil
}

// The lib's BYTES are read once; every unit still parses and binds its own copy,
// because a bound SourceFile carries symbols and sharing one across checkers would
// change what is measured.
var libTexts map[string]string

func loadLibTexts() error {
	fs := bundled.WrapFS(osvfs.FS())
	libTexts = map[string]string{}
	for _, lib := range libFiles {
		lp := tspath.CombinePaths(bundled.LibPath(), lib)
		b, ok := fs.ReadFile(lp)
		if !ok {
			return fmt.Errorf("lib not readable: %s", lp)
		}
		libTexts[lp] = b
	}
	return nil
}

func dumpTypes(out *bytes.Buffer, fileName string, cwd string, text string) {
	p := &prog{
		byName: map[string]*ast.SourceFile{},
		libs:   map[tspath.Path]bool{},
		cwd:    cwd,
		opts:   &core.CompilerOptions{SkipDefaultLibCheck: core.TSTrue, NoErrorTruncation: core.TSTrue},
	}
	add := func(path string, text string) *ast.SourceFile {
		fn := tspath.GetNormalizedAbsolutePath(path, cwd)
		opts := ast.SourceFileParseOptions{FileName: fn, Path: tspath.ToPath(fn, cwd, true)}
		sf := parser.ParseSourceFile(opts, text, core.GetScriptKindFromFileName(fn))
		p.files = append(p.files, sf)
		p.byName[fn] = sf
		return sf
	}
	for _, lib := range libFiles {
		lp := tspath.CombinePaths(bundled.LibPath(), lib)
		p.libs[add(lp, libTexts[lp]).Path()] = true
	}
	unit := add(fileName, text)
	c, _ := checker.NewChecker(p, nil)
	for _, d := range c.GetDiagnostics(context.Background(), unit) {
		fmt.Fprintf(out, "C %d %d %d\n", d.Pos(), d.End(), d.Code())
	}
	for _, node := range forEachASTNode(unit.AsNode()) {
		if node == unit.AsNode() || skipForType(node) {
			continue
		}
		var t *checker.Type
		if isNamelessTypeOnlyImportClause(node) {
			continue
		}
		if ast.IsExpressionWithTypeArgumentsInClassExtendsClause(node.Parent) {
			t = c.GetTypeAtLocation(node.Parent)
		}
		if t == nil || checker.IsTypeAny(t) {
			t = c.GetTypeAtLocation(node)
		}
		if t == nil {
			continue
		}
		fmt.Fprintf(out, "T %d %d %d %s\n", node.Kind, node.Pos(), node.End(), typeEscape(c.TypeToString(t)))
	}
}

// ───────────────────────── emit.go ─────────────────────────
//
// THE EMIT YARDSTICK (slice 229): the JavaScript the reference's OWN emitter writes
// for the unit — `compiler.Program.Emit` over a one-file program, the unit as its
// only root, the bundled lib, the DEFAULT compiler options (target LatestStandard,
// module per target), JS only. This is the checker yardstick's shape one stage
// further: per UNIT and under the default options, so it measures the printer,
// the script transformers and the emit resolver, and none of the per-case
// `// @target`/`// @module` directives — those belong to the driver chapter, whose
// yardstick is the reference's own `.js` baseline per CASE. The body is the text
// of the `.js`/`.jsx`/`.mjs`/`.cjs` output exactly as handed to WriteFile; a unit
// the reference does not emit (a `.d.ts`, a `.json` under these options) answers
// an empty body, which is a MATCH only when the port emits nothing either.
func dumpEmit(out *bytes.Buffer, fileName string, cwd string, text string) {
	fn := tspath.GetNormalizedAbsolutePath(fileName, cwd)
	fs := bundled.WrapFS(vfstest.FromMap(map[string]string{fn: text}, true))
	host := compiler.NewCompilerHost(cwd, fs, bundled.LibPath(), nil, nil)
	config := &tsoptions.ParsedCommandLine{
		ParsedConfig: &core.ParsedOptions{
			CompilerOptions: &core.CompilerOptions{},
			FileNames:       []string{fn},
		},
	}
	program := compiler.NewProgram(compiler.ProgramOptions{Config: config, Host: host, SingleThreaded: core.TSTrue})
	sf := program.GetSourceFile(fn)
	if sf == nil {
		return
	}
	program.Emit(context.Background(), compiler.EmitOptions{
		TargetSourceFile: sf,
		EmitOnly:         compiler.EmitOnlyJs,
		WriteFile: func(name string, text string, data *compiler.WriteFileData) error {
			if tspath.HasJSFileExtension(name) {
				out.WriteString(text)
			}
			return nil
		},
	})
}

// ───────────────────────── the batch ─────────────────────────

//go:linkname astNextNodeId github.com/microsoft/typescript-go/internal/ast.nextNodeId
var astNextNodeId atomic.Uint64

//go:linkname astNextSymbolId github.com/microsoft/typescript-go/internal/ast.nextSymbolId
var astNextSymbolId atomic.Uint64

// resetIds puts the reference into the state a fresh process has: see the header.
func resetIds() {
	astNextNodeId.Store(0)
	astNextSymbolId.Store(0)
}

type artifact struct {
	name string
	dump func(out *bytes.Buffer, fileName string, cwd string, text string)
}

var artifacts = []artifact{
	{"tokens", func(out *bytes.Buffer, fileName string, cwd string, text string) { dumpTokens(out, fileName, text) }},
	{"ast", dumpAst},
	{"jsdoc", dumpJsdoc},
	{"symbols", dumpSymbols},
	{"flow", dumpFlow},
	{"types", dumpTypes},
	{"emit", dumpEmit},
}

// capture runs one dump under recover: rc 0 with its output, or rc 3 with the
// panic in err and whatever the dump had written so far in out — the standalone
// oracles' exit-3 contract, per artifact instead of per process.
func capture(a artifact, fileName string, cwd string, text string) (rc int, out []byte, err []byte) {
	var buf bytes.Buffer
	resetIds()
	func() {
		defer func() {
			if r := recover(); r != nil {
				rc = 3
				err = []byte(fmt.Sprintf("the reference panicked: %v\n", r))
			}
		}()
		a.dump(&buf, fileName, cwd, text)
	}()
	return rc, buf.Bytes(), err
}

type unit struct {
	name    string
	content string
}

func splitCase(casePath string) (units []*unit, rc int, errText string) {
	text, err := os.ReadFile(casePath)
	if err != nil {
		return nil, 1, err.Error()
	}
	func() {
		defer func() {
			if r := recover(); r != nil {
				rc = 3
				errText = fmt.Sprintf("the reference's splitter rejected this case: %v", r)
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
	if rc != 0 {
		return nil, rc, errText
	}
	if err != nil {
		return nil, 1, err.Error()
	}
	return units, 0, ""
}

func body(out *bytes.Buffer, b []byte) {
	out.Write(b)
	out.WriteByte('\n')
}

func doCase(outDir string, cwd string, casePath string, name string) []byte {
	var out bytes.Buffer
	fmt.Fprintf(&out, "==== TSCALY-CASE %s\t%s\n", name, casePath)
	units, rc, errText := splitCase(casePath)
	fmt.Fprintf(&out, "==== TSCALY-SPLIT %d %d\n", rc, len(errText))
	body(&out, []byte(errText))
	if rc != 0 {
		return out.Bytes()
	}
	for i, u := range units {
		// The path the unit WOULD have had on disk — the parse reads ScriptKind and
		// the `.d.ts` flag off it, so it has to be the same string as before.
		written := filepath.Join(outDir, "cases", name, "units", fmt.Sprintf("u%02d_%s", i, filepath.Base(u.name)))
		fmt.Fprintf(&out, "==== TSCALY-UNIT %d %d\t%s\t%s\n", i, len(u.content), u.name, written)
		body(&out, []byte(u.content))
		for _, a := range artifacts {
			arc, aout, aerr := capture(a, written, cwd, u.content)
			fmt.Fprintf(&out, "==== TSCALY-REF %s %d %d %d\n", a.name, arc, len(aout), len(aerr))
			body(&out, aout)
			body(&out, aerr)
		}
	}
	return out.Bytes()
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: batch <out dir>  < cases.tsv   (lines: <case file>\\t<case name>)")
		os.Exit(2)
	}
	outDir := os.Args[1]
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if err := loadLibTexts(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	type job struct {
		casePath, name string
	}
	var jobs []job
	sc := bufio.NewScanner(os.Stdin)
	sc.Buffer(make([]byte, 1<<20), 1<<20)
	for sc.Scan() {
		line := sc.Text()
		if line == "" {
			continue
		}
		casePath, name, ok := strings.Cut(line, "\t")
		if !ok {
			fmt.Fprintf(os.Stderr, "batch: a case line without a tab: %q\n", line)
			os.Exit(2)
		}
		jobs = append(jobs, job{casePath, name})
	}
	w := bufio.NewWriterSize(os.Stdout, 1<<20)
	for _, j := range jobs {
		w.Write(doCase(outDir, cwd, j.casePath, j.name))
		// A case is flushed as soon as it is done, so a reader can follow the
		// stream and a crash loses nothing that was finished.
		w.Flush()
	}
	w.Flush()
}
