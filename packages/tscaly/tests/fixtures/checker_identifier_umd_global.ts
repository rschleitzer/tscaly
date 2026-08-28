// Slice 91. onSuccessfullyResolvedSymbol's SECOND block — TS2686, the UMD global
// referenced from a module — and the measurement that says the block is written
// with NO INPUT.
//
// ★★★ THE BLOCK IS DECIDABLE AND ITS INPUT IS NOT. Its test is that EVERY
// declaration of the resolved symbol is a NamespaceExportDeclaration or a source
// file with GlobalExports, and both halves are answerable here — the binder's
// global_exports slot is exactly that field. What cannot be answered is getting
// the symbol at all: `export as namespace Lib` declares `Lib` into GlobalExports,
// which the walk reaches only through `lookup(r.Globals, …)` — §3.11 — so the
// resolution MISSES and the reference itself answers TS2304 on the line below.
// The block is ported at its place rather than left out, and this fixture is the
// sentence saying it has no input until the table lands.
export as namespace Lib;
export {};
Lib;
