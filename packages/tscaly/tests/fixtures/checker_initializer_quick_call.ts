// getQuickTypeOfExpression's CALL arm once its four conjuncts pass — the
// "common case of a call to a function with a single non-generic call signature
// where we can just fetch the return type without checking the arguments".
//
// * THE TWO FORKS INSIDE THE ARM ARE ONE ROW HERE: isCallChain picks
// getReturnTypeOfSingleNonGenericSignatureOfCallChain and everything else
// getReturnTypeOfSingleNonGenericSignature, and both end in getSingleSignature —
// so the second line stops at the same tag as the first and the fork is not yet
// work-list visible. That is why they may share a file where the Symbol pair may
// not.
//
// * NOTHING IS DECLARED, DELIBERATELY. Every shape that would introduce the names
// — a `declare function`, a `declare const` — records its own stop first
// (`get-return-type-from-annotation`, then the trailing shadow block) and would
// take the first-wins slot away from the arm this file aims at. The unresolved
// names cost a diagnostic that diagcheck reads and no tag at all.
let c = g();
let k = o?.m();
