// Slice 60. checkTypeParametersNotReferenced — a fixture that produces NO
// diagnostic of ours, and §3.5ap's rule applied on purpose: a fixture that gates
// nothing is invisible until a control aims at it.
//
// ★★★ WHAT IT MEASURES IS THE WALK, NOT THE REPORT. The reference answers TS2744
// (*type parameter defaults can only reference previously declared type
// parameters*) on the `A` below; this port stops one call short of it, at
// getTypeFromTypeReference. What is ported is the child walk that decides whether
// that resolution is ASKED at all — free, and the reason `<T = string>` is not
// reported as a hole.
//
// ★★ THE TAG IS THE DEFAULT'S KIND AND NOT THE TYPE PARAMETER'S, which is this
// slice's histogram moving one level down: checkSourceElement(DefaultType) runs
// BEFORE getDeclaredTypeOfTypeParameter, so the unit lands at `check` /
// KindTypeReference rather than at `get-symbol-of-declaration` /
// KindTypeParameter. The row that inverts the walk's kind test is what pins it.
export {};
function f<T = A, A>(): void {}
