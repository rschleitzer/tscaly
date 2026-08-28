// The comma operator inside a CALL, which is where isIndirectCall's exemption
// lives — and where this port cannot go. `(0, f)()` is an ExpressionStatement
// whose expression is a CallExpression, so the dispatch stops at
// check-call-expression before the comma is ever checked: the reference reports
// TS2695 here (`f` is not an access expression and is not `eval`, so the
// exemption does NOT apply) and this port reports nothing at all.
declare const f: () => void;
(0, f)();
