// Slice 62. What the method arm buys, and it is the same shape the property arm's
// yield has: a WALK. checkSignatureDeclaration's parameter list and return type were
// unreachable from a type literal until this slice.
//
// ★★★ TS2371 IS THE PROOF AND IT COMES FROM THREE FUNCTIONS DOWN — the method arm,
// checkFunctionOrMethodDeclaration, checkSignatureDeclaration's
// `checkSourceElements(node.Parameters())`, the Parameter arm of the switch, and
// finally checkVariableLikeDeclaration's initializer report. A method signature has
// no body, so `NodeIsMissing(fn.Body())` is true and a parameter initializer is
// refused.
//
// ★ The second declaration reports nothing and is here for the walk rather than for a
// report: a type literal in a parameter's annotation and another in the return type
// are two more arms of slice 61 reached through this one.
export {};
declare const a: { m(p = 1): void };
declare const b: { m(p: { q: string }): { r: number } };
