// Slice 58. TS1147 and TS1194 — the pair chosen by the node's KIND, and they are
// not each other's negation: an import in a namespace says *import declarations
// in a namespace cannot reference a module*, an export says *export declarations
// are not permitted in a namespace*.
//
// ★★ THE CONTEXT HEAD DOES NOT CATCH THESE. checkGrammarModuleElementContext
// permits a ModuleBlock parent — that is what makes `namespace N { export … }`
// legal in general — so both statements run all the way into
// checkExternalImportOrExportDeclaration, and the report lands on the MODULE
// NAME rather than on the statement.
//
// ★★★ THE EXPORT LINE IS THE INTERESTING ONE, because TS1194 is reported TWICE in
// this arm from two different places: here, on the specifier, and again at the
// bottom of checkExportDeclaration on the whole node when there is no specifier.
// Only one of them fires per statement — the external check RETURNS false — and a
// port that let the guard through would emit both.
namespace N {
    import a from "./a";
    export { b } from "./b";
}
