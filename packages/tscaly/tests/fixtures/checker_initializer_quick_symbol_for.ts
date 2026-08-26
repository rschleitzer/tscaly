// The `Symbol.for` half of isSymbolOrSymbolForCall, and it is a rewrite rather
// than a second test: the reference steps LEFT past a property access whose name
// is literally `for` BEFORE asking whether the callee is the identifier `Symbol`.
//
// * A PORT THAT SKIPPED THE REWRITE would answer `check-call-expression` for this
// file and the undecidable term for its sibling, which is the shape a single
// two-line fixture cannot tell apart.
let e = Symbol.for("x");
