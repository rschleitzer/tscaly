// Slice 58. TS1141 — `String literal expected`, the FIRST report of
// checkExternalImportOrExportDeclaration and the one that says why the check
// exists at all: parseModuleSpecifier deliberately accepts an arbitrary
// expression ("we check to ensure that it is only a string literal later in the
// grammar check pass"), so the parser is silent here and the checker is the only
// thing that speaks.
//
// ★★ THE THREE KINDS REACH IT BY THREE DIFFERENT SLOTS, which is exactly what
// ast.GetExternalModuleName is for: an import and an export declaration answer
// with their ModuleSpecifier, an `import = require(…)` with the EXPRESSION inside
// its ExternalModuleReference. Break the last arm and only the third line goes
// quiet.
//
// ★ Every one of the three RETURNS false after reporting, so nothing further in
// the arm runs — which is why this unit's import lines carry no check-import-binding
// tag while checker_import_defer.ts's do.
declare const m: string;
import a from m;
export { b } from m;
import c = require(m);
