// `x as const` — the ONE shape IsAssertionExpression admits and
// getQuickTypeOfExpression refuses. IsConstTypeReference is three tests over an
// ordinary TypeReference whose name happens to be the word `const`, so dropping
// it does not make the arm answer differently: it makes the arm ask
// getTypeFromTypeNode for a type reference, which is a DIFFERENT stop.
//
// * THAT IS WHY THE FILE IS SEPARATE. Under a sibling's `1 as string` the new stop
// would never be first-wins, and the control aimed at the exclusion would come
// back green whatever it broke.
let c = 1 as const;
