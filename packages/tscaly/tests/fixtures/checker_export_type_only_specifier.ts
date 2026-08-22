// Slice 50. TS2207 — `The type modifier cannot be used on a named export when
// export type is used on its export statement`, i.e. checkGrammarExportDeclaration
// through checkGrammarTypeOnlyNamedImportsOrExports.
//
// ★★★ WHAT IT PINS IS THE ORDER OF TWO LINES IN THE ARM. The export declaration
// carries a module specifier, so the statement is stopped one call later by
// checkExternalImportOrExportDeclaration — and this grammar check stands BEFORE
// that bail in the reference. Move the report behind it and this unit goes silent
// while every other fixture of the slice stays green.
export type { type A } from './m';
