// checkParenthesizedExpression is one line — `checkExpressionEx(node.Expression(),
// checkMode)` — so a parenthesised expression has its operand's type, at any
// depth. The witness is again the section change: both statements complete and
// the unit stops in the type walk.
//
// ★ The second half is the more interesting one: an UNPORTED operand inside
// parentheses takes ITS OWN arm's tag rather than one naming the parenthesis, so
// the work list never grows a `check-parenthesized-expression` row. Which of the
// two reports first is the first statement's business — this file's tag comes
// from the walk, and the one below is the reason the file also holds `(x + 1)`.
(null);
((null));
