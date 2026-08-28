// checkReferenceExpression's second report, TS2779: the left-hand side IS an
// access expression, and it is an optional chain.
declare const o: { a?: number };
o?.a = 1;
