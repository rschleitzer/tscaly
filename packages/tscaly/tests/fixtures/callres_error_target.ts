// Slice 108. invocationErrorDetails' TARGET, and the finding is that the one line
// that can move it has NO INPUT.
//
// ★★★ THE RETARGET IS `IsPropertyAccessExpression(errorTarget) &&
// IsCallExpression(errorTarget.Parent)`, i.e. a CALL through a property access — and
// invocationError is unreachable from the call side, because isUntypedFunctionCall's
// third disjunct stops at `global-function-type` (§3.11) for exactly the population
// TS2349 is about. From the `new` side the parent is a NewExpression, so the
// condition is false by construction. **This fixture therefore pins the span the
// port DOES produce: the whole property access, not its name.**
//
// ★★ It is kept for §3.5ap's reason — a fixture that gates nothing is invisible
// until a control aims at it — and one of this slice's controls does, predicting the
// silence.
declare const o: { p: { a: number } };
new o.p();
