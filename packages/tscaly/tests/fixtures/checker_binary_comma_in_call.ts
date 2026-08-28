// The comma operator inside a CALL, which is where isIndirectCall's exemption
// lives. `(0, f)()` is an ExpressionStatement whose expression is a
// CallExpression, and the reference reports TS2695 here — `f` is not an access
// expression and is not `eval`, so the exemption does NOT apply.
//
// ★★★ SLICE 88 WROTE THIS FIXTURE AS A NEGATIVE CONTROL AND SLICE 89 EXPIRED IT.
// Then the dispatch stopped at check-call-expression before the comma was ever
// checked and this port reported nothing at all; now resolveCallExpression checks
// the CALLEE, the parenthesised comma is reached, and the line is emitted. It is
// the ONE diagnostic slice 89 adds outside its own fixtures, and it is what makes
// slice 88's g29 — isIndirectCall forced FALSE, then UNGATED — a live row.
declare const f: () => void;
(0, f)();
