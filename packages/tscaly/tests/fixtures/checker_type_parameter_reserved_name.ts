// Slice 60. checkTypeNameIsReserved's third caller — TS2368, *type parameter name
// cannot be 'any'* — which sits BELOW this arm's stop and is ported anyway, on the
// convention this file has followed since slice 52: record_unported marks the unit
// and does not return, and diagcheck's relation is a subsequence.
//
// ★★★ THE THIRD LINE IS THE ASYMMETRY SLICE 57 WROTE DOWN, SEEN FROM THE OTHER
// SIDE, AND IT IS THE REASON THIS FIXTURE HAS ONE. checkTypeAliasDeclaration
// computes its type parameters AFTER checkExportsOnMergedDeclarations, so the
// alias arm never calls checkTypeParameters at all — the reference reports TS2368
// on `never` there and this port does not. That absence is deliberate and is a
// subsequence, not a hole in this slice; the slice that lifts the alias's stop
// picks it up.
export {};
interface I<any> { x: any }
function f<string>(): void {}
type A<never> = never;
