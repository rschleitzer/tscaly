// getQuickTypeOfExpression's NEW arm — the same "fetch the return type without
// checking the arguments" optimisation over a CONSTRUCT signature, and a separate
// `case` upstream rather than a branch of the call one.
//
// * ITS OWN FILE for the first-wins reason its siblings give: under the call
// fixture's first line this arm could never be seen to move.
let h = new Date();
