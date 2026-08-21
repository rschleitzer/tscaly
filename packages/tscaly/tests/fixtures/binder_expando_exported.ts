// slice 38 — lookupName's `core.OrElse(local.ExportSymbol, local)`.
//
// In a module, `export function f` produces TWO symbols: a local and the export
// symbol the module's exports table holds, linked by ExportSymbol. An expando
// must extend the EXPORT symbol — that is the one a consumer of the module sees —
// so the lookup follows the link rather than answering the local.
//
// The dump makes the difference visible: `a` appears in the exports of the symbol
// the `x` line points the local at, not in the local's own.
export function f() {}
f.a = 1;
