// The reference's own noImplicitAnyLoopCrash, as a LOCAL fixture: its only other
// witness is a stage-2 submodule case, and a defect whose only gate is a corpus
// case is a defect whose gate can move under a pin bump.
//
// `bar` is auto-typed, so the assignment inside the loop is the auto arm of
// getTypeAtFlowAssignment, which types the right-hand side — and the right-hand
// side reads `bar` again. What makes that terminate is getTypeAtFlowLoopLabel's
// in-process row, and what would HIDE that row is checkExpressionCached, which
// clears the loop stack: getEffectiveCallArguments therefore checks a spread
// argument UNCACHED while the stack is non-empty. Without that fork the walk
// re-enters the junction at depth 0 forever (measured: rc 139).
//
// The type to watch is the inner `bar`, which is the incomplete union
// `number | undefined` — undefined from the path that does not enter the loop,
// number from the assignment itself.
let foo = () => {};
let bar;
while (1) {
    bar = ~foo(...bar);
}
