// SLICE 77: TS2499, and the report that could not be reached until the once-block
// became its own procedure.
//
// ★★★ THE REACHABILITY IS THE POINT. An interface WITH an extends clause stops at
// `resolve-entity-name` inside getDeclaredTypeOfSymbol, which sits in the
// once-block — and while that block was inline, its `return` took the arm's whole
// tail with it. So a report ABOUT an extends clause was unreachable for exactly
// the declarations that have one. Lifting the block into a procedure is what makes
// this file produce a line at all.
interface K extends foo() { }
