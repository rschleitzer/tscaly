// Slice 65. checkExportsOnMergedDeclarations' SECOND report, TS2652 — and this
// file is also the whole witness for the LOCAL SYMBOL slot the head opens with.
//
// ★★★ `export default class C {}` OWNS TWO SYMBOLS AND THE CHECK NEEDS THE OTHER
// ONE. The declaration's `symbol` is the EXPORT, whose name is `default`; the
// namespace below merges with the LOCAL symbol `C`, so it is only through
// `node.LocalSymbol()` that the class and the namespace are seen as one merge at
// all. Take the slot away and the head falls through to the export symbol, whose
// ExportSymbol is null, and returns — the report vanishes without a word.
//
// ★★ THE THREE ACCUMULATORS ARE NOT SYMMETRIC, which is why this reports TS2652
// and not TS2395: `nonDefaultExportedDeclarationSpaces` is exported OR
// non-exported, so a default export is intersected against both of the other two
// at once. The class contributes ExportType|ExportValue to the default
// accumulator, the instantiated namespace ExportNamespace|ExportValue to the
// non-exported one, and ExportValue is the overlap.
//
// ★ The namespace must be INSTANTIATED for that overlap to exist — an empty one
// answers ExportNamespace alone — which is the same term
// checker_namespace_merged_before_class.ts turns on one head further down.
export default class C {}
namespace C { export var x = 1; }
