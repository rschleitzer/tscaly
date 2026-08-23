// Slice 60. checkTypeParameters' duplicate-name loop — TS2300, *duplicate
// identifier*.
//
// ★★★ THREE PARAMETERS, BECAUSE AT TWO BOTH READINGS AGREE. `for j := range i`
// reports once per matching PREDECESSOR, so `<T, T, T>` is three diagnostics: one
// on the second T and two on the third, the latter pair at the same span. Two
// parameters would be one diagnostic under that rule and under the wrong one
// ("once per duplicate") alike, so the fixture would prove nothing.
//
// ★★ IT IS THE BINDER'S `Node.Symbol()` AND NOT getSymbolOfDeclaration, which is
// the whole reason this report is live in a slice that stops at the merge: the
// comparison needs the slot the binder wrote and nothing more. The second
// declaration below carries variance MODIFIERS to show that the symbol comparison
// does not care about them.
export {};
function f<T, T, T>(): void {}
interface I<in out U, U> { u: U }
