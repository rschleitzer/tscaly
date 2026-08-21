// SPDX-License-Identifier: Apache-2.0
//
// types — the CHECKER yardstick, and the fifth artifact of this suite.
//
// Dumps the reference's CHECK of one file. Two sections, in this order:
//
//	C <pos> <end> <code>                 one line per checker diagnostic
//	T <kind> <pos> <end> <typeString>    one line per node the type walk asks about
//
// ★★★ WHY IT IS A SEPARATE ARTIFACT, one phase later than §3.5bd's argument for
// the jsdoc dump and §3.5bv's for the symbols one: a TYPE is not in the tree and
// not on a symbol. It is computed on demand, memoised inside the checker, and
// never written back — so with four artifacts a port that computes NO types and a
// port that computes WRONG ones compare exactly equal, in both directions. The
// diagnostics are the same case seen from the other side: GetDiagnostics answers
// out of the checker's own list, which no parse or bind artifact reaches.
//
// ★★★ THE PROGRAM IS A STUB AND THE LIB SET IS FIXED — the two decisions that
// shape every number this yardstick will ever print, so they are stated here and
// measured rather than assumed.
//
// The reference's checker needs a Program, not a file: `checker.NewChecker` takes
// an interface of some forty methods (module resolution, project references, emit
// host questions). The suite's unit of comparison is ONE FILE (§3.5ac), and every
// other oracle here parses one file and hands it on. So this oracle implements
// that interface as a stub over a fixed file set — the lib files plus the unit —
// and answers the resolution questions with nothing. Consequences, all of them
// symmetric because our side will do the same:
//
//   - an `import` resolves to nothing, so a module-bearing unit reports its
//     "cannot find module" the same way on both sides;
//   - the per-case `@target` / `@lib` / `@module` directives are NOT honoured;
//   - the lib set is lib.es5.d.ts and nothing else.
//
// ★★ THE LIB SET IS THE ONE NORMALISATION AND IT IS PRICED. The reference's
// default is lib.d.ts, which references es5 + dom + webworker.importscripts +
// scripthost — about 50 000 lines against es5's 4 599. Measured over 400
// submodule cases, the two lib sets give a DIFFERENT diagnostic set for **12 of
// them, 3 %**, and es5 alone costs 5.4 ms per unit against 18.7 ms. The es5 set
// is therefore the committed choice, with two conditions attached: the delta is a
// measured 3 % and not a guess, and switching the set later moves every number
// but does NOT change the artifact's FORMAT — which is the expensive kind of
// change (§3.5ac, the case→unit move that invalidated three sections of numbers).
//
// ★★★ THE TYPE WALK'S EXCLUSIONS ARE LOAD-BEARING AGAINST A CRASH, not a filter
// for readability. `GetTypeAtLocation` at EVERY node panics, and the reference's
// own walker is what says which nodes may be asked — so the predicate below is
// TRANSCRIBED from it (testutil/tsbaseline/type_symbol_baseline.go,
// writeTypeOrSymbol's non-symbol half) rather than invented: "don't try to get
// the type of something that is already a type", with the type-alias name as its
// exception. That walker cannot be CALLED here — it takes a
// compiler.ProgramLike, i.e. the real program this oracle deliberately does not
// build — which is why it is transcribed, and why the transcription is named as
// such.
//
// ★★★ AND THE TRANSCRIPTION IS NOT ENOUGH: ONE EXCLUSION IS OURS, because the
// reference's walker would crash too. `import type { A } from './x'` — one line
// of valid TypeScript — is a nil dereference inside the checker, and the only
// reason the reference's own type baseline never meets it is that the corpus
// cases carrying that syntax declare `@noTypesAndSymbols: true`. It is measured
// down to the shape (isNamelessTypeOnlyImportClause, below) and swept: **0
// failures over 2 867 files**, the 2 000 + 400 raw submodule cases and every
// fixture.
//
// ★★ THE TYPE STRING IS `Checker.TypeToString`, NOT the baseline's. The .types
// baseline prints through NewNodeBuilder + TypeToTypeNode + the emit printer,
// i.e. through the declaration PRINTER — 3 585 lines of nodebuilder plus the
// printer, a dimension of its own and not the checker. TypeToString is the
// checker's own answer to "what is this type called", and it is the one this port
// has to reproduce first. When the printer dimension arrives, the baseline's
// formatter is the artifact to add, beside this one and not instead of it.
//
// ★ The KIND is in the T line because a type alone cannot say which node was
// asked: the walk's exclusions decide WHICH nodes appear, and a port whose
// predicate differs would otherwise show up as a shifted list of positions with
// no clue which test moved.
//
// ★★★ AND WHEN THE REFERENCE CANNOT ANSWER AT ALL, THIS EXITS 3. Two lines of
// JavaScript — `interface I { /** @type {string} */ m() }` in a .js file — nil
// dereference the checker from GetDiagnostics, not from the type walk:
// checkFunctionOrMethodDeclaration asks getTypeFromTypeNode for the method's
// reparsed JSDoc type, whose Parent is nil, and getAliasSymbolForTypeNode reads
// it. It is not the stub program's doing — a Parent is parse-time state, and a
// walk of the whole tree finds NO nil parent, because the node lives in the
// `full_signature` slot that ForEachChild deliberately does not visit (§3.5ao).
// The shape is bounded: an interface METHOD in a .js file, with any @type; a
// function declaration, a `declare class` method and the same source as .ts are
// all fine.
//
// So this oracle recovers at the top level and exits 3, which the comparator
// counts as its own class — "the reference could not answer this unit" — and
// prints with the unit named. It is NOT a failure of the port and it is NOT a
// silent pass: a missing measurement that cannot be seen is the one thing this
// suite exists to prevent, and a checker of 60 000 lines will do this again.
//
// Usage:  types <file>

package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"slices"
	"strings"

	"github.com/microsoft/typescript-go/internal/ast"
	"github.com/microsoft/typescript-go/internal/binder"
	"github.com/microsoft/typescript-go/internal/bundled"
	"github.com/microsoft/typescript-go/internal/checker"
	"github.com/microsoft/typescript-go/internal/core"
	"github.com/microsoft/typescript-go/internal/module"
	"github.com/microsoft/typescript-go/internal/packagejson"
	"github.com/microsoft/typescript-go/internal/parser"
	"github.com/microsoft/typescript-go/internal/symlinks"
	"github.com/microsoft/typescript-go/internal/tsoptions"
	"github.com/microsoft/typescript-go/internal/tspath"
	"github.com/microsoft/typescript-go/internal/vfs/osvfs"
)

// The lib set. See the header: es5 alone, priced at a 3 % diagnostic delta
// against the reference's default lib.d.ts closure.
var libFiles = []string{"lib.es5.d.ts"}

// ── the stub program ────────────────────────────────────────────────────────
//
// Everything the checker asks that is not "which files are there" and "what are
// the options" answers nothing. Each method is the reference's own signature; the
// bodies are the stub. `IsSourceFileDefaultLibrary` is the one that has to be
// real, because SkipDefaultLibCheck reads it.

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

func (p *prog) FileExists(fileName string) bool                { return p.byName[fileName] != nil }
func (p *prog) GetSourceFile(fileName string) *ast.SourceFile  { return p.byName[fileName] }
func (p *prog) UseCaseSensitiveFileNames() bool                { return true }
func (p *prog) GetCurrentDirectory() string                    { return p.cwd }
func (p *prog) CommonSourceDirectory() string                  { return "" }
func (p *prog) GetGlobalTypingsCacheLocation() string          { return "" }
func (p *prog) GetSymlinkCache() *symlinks.KnownSymlinks       { return nil }
func (p *prog) GetRedirectTargets(path tspath.Path) []string   { return nil }
func (p *prog) GetPackagesMap() map[string]bool                { return nil }
func (p *prog) GetNearestAncestorDirectoryWithPackageJson(dirname string) string { return "" }

func (p *prog) GetSourceFileForResolvedModule(fileName string) *ast.SourceFile {
	return p.byName[fileName]
}

func (p *prog) IsSourceFileDefaultLibrary(path tspath.Path) bool { return p.libs[path] }

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

// ── the type walk ───────────────────────────────────────────────────────────

// forEachASTNode, transcribed: the reference's own pre-order walk, with its
// Reparsed rule. A reparsed node is JSDoc-derived syntax that is not in the
// source, so it is skipped — except for the two positions where a reparsed type
// IS the thing being asked about.
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

// The exclusions, transcribed from writeTypeOrSymbol's non-symbol half. See the
// header: asking a type node for its type is a nil dereference inside the
// reference, so this is a contract and not a filter.
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

// ONE LINE PER NODE, and the string is the last field so it may contain spaces —
// the symbols dump's rule, for the same reason (a type name is not a token).
// Newlines and tabs are escaped because a dump line is a line.
func escape(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "\\r")
	return strings.ReplaceAll(s, "\t", "\\t")
}

// ★★★ THE ONE EXCLUSION THAT IS OURS, and it stands in front of a nil
// dereference INSIDE THE REFERENCE. `import type { A } from './x'` — a type-only
// import clause with named bindings and no name — is an `ast.IsTypeDeclaration`,
// so `getTypeOfNode` takes its type-declaration arm and calls
// `getSymbolOfDeclaration`, which answers nil for a clause that declares nothing
// itself (the SPECIFIERS carry the symbols). `getDeclaredTypeOfSymbol(nil)` then
// dereferences it: SIGSEGV, one line of TypeScript, from a public API.
//
// ★ The three neighbouring spellings are all fine and each says why this one is
// not: a VALUE import (`import { A }`) is no type declaration; a DEFAULT type
// import (`import type A`) has a name and therefore a symbol; and a nameless
// `export default class {}` also has one ("default"). So the shape is exactly
// "type-only, named bindings, no name" — measured, not guessed, and the guard is
// written to that shape rather than to `GetSymbolAtLocation() == nil`, which is a
// DIFFERENT question and drops the default class's type as well.
func isNamelessTypeOnlyImportClause(node *ast.Node) bool {
	return node.Kind == ast.KindImportClause && node.IsTypeOnly() && node.Name() == nil
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: types <file>")
		os.Exit(2)
	}
	// The recover is here and not around the two sections separately, because a
	// panic inside the checker leaves it in an unknown state: what it has already
	// answered is not trustworthy either.
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "the reference panicked: %v\n", r)
			os.Exit(3)
		}
	}()
	text, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	p := &prog{
		byName: map[string]*ast.SourceFile{},
		libs:   map[tspath.Path]bool{},
		cwd:    cwd,
		// NoErrorTruncation is the harness's own setting: a truncated type name
		// would make the T section depend on a display budget.
		opts: &core.CompilerOptions{SkipDefaultLibCheck: core.TSTrue, NoErrorTruncation: core.TSTrue},
	}
	add := func(path string, text string) *ast.SourceFile {
		fn := tspath.GetNormalizedAbsolutePath(path, cwd)
		opts := ast.SourceFileParseOptions{FileName: fn, Path: tspath.ToPath(fn, cwd, true)}
		sf := parser.ParseSourceFile(opts, text, core.GetScriptKindFromFileName(fn))
		p.files = append(p.files, sf)
		p.byName[fn] = sf
		return sf
	}

	fs := bundled.WrapFS(osvfs.FS())
	for _, lib := range libFiles {
		lp := tspath.CombinePaths(bundled.LibPath(), lib)
		b, ok := fs.ReadFile(lp)
		if !ok {
			fmt.Fprintln(os.Stderr, "lib not readable:", lp)
			os.Exit(1)
		}
		p.libs[add(lp, b).Path()] = true
	}
	unit := add(os.Args[1], string(text))

	c, _ := checker.NewChecker(p, nil)

	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()

	for _, d := range c.GetDiagnostics(context.Background(), unit) {
		fmt.Fprintf(out, "C %d %d %d\n", d.Pos(), d.End(), d.Code())
	}

	for _, node := range forEachASTNode(unit.AsNode()) {
		if node == unit.AsNode() || skipForType(node) {
			continue
		}
		// The base-class workaround is the reference's, verbatim in intent: ask
		// the ExpressionWithTypeArguments so `class D extends C` reports `C` and
		// not `typeof C`.
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
		fmt.Fprintf(out, "T %d %d %d %s\n", node.Kind, node.Pos(), node.End(), escape(c.TypeToString(t)))
	}
}
