// SLICE 77: the SPAN of TS2499, and the only fixture that can see it.
//
// ★★★ THE REPORT IS ON THE EXPRESSION AND NOT ON THE HERITAGE ELEMENT — the
// reference writes `c.error(expr, ...)` — and the two coincide for every OTHER
// shape, because an ExpressionWithTypeArguments with no type arguments spans
// exactly its expression. Control g09 moves the report to the element and came
// back UNGATED against the first two TS2499 fixtures for that reason. Type
// arguments are what separate the nodes: here the expression is `a["b"]` at
// 42..48 and the element runs to 56.
//
// ★★ A span is the half of a diagnostic no message text carries, so a row that
// can only move a span needs a fixture whose two candidate nodes differ — and
// "the two spellings agree on every fixture I have" is not a proof that they
// agree.
declare const a: any;
interface K extends a["b"]<string> { }
