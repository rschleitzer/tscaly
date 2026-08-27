// SLICE 82: the ANNOTATED half of the split row, and the only shape that still needs
// the flow graph. `f(): number { }` computes its type, fails the void/any/undefined
// early return, passes the three syntactic terms of the second guard and stops at
// functionHasImplicitReturn — `flow-graph`, the row slice 77 named for the two
// chapters that share it.
//
// ★★★ THE BODY IS EMPTY ON PURPOSE AND THE REFERENCE REPORTS TS2355 HERE. That is a
// diagnostic this port LOSES, which a subsequence cannot see — so the fixture's
// witness is the DIAGPIN and the TAG, and the loss is the price of the flow graph
// stated at the one place it can be read off.
//
// ★ An earlier draft wrote `return x` in the body and measured
// `get-signature-from-declaration` instead: check_return_statement stops inside the
// BODY walk, which runs before this chapter, and record_unported is first-wins.
function annotatedReturn(x: number): number {
}
