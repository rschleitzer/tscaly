// checkReferenceExpression's first report, TS2364: the left-hand side is neither
// an identifier nor an access expression.
declare function f(): number;
f() = 1;
