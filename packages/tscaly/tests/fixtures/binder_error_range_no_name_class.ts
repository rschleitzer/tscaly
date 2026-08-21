// slice 45 — the same fallback, the other KIND and the other ORDER.
//
// The anonymous declaration is the EXISTING one here, so the fallback is reached
// through the loop over a symbol's declarations rather than through the new
// declaration below it — and the kind is a ClassDeclaration, which is on
// GetErrorRangeForNode's declaration-name list exactly like the function is. Both
// halves matter: the arm is not FunctionDeclaration-specific, and it is not a
// property of being reported last.
export default class { }
export default 0;
