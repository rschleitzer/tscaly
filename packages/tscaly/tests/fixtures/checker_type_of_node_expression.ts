// The IsExpressionNode arm through IsInExpressionContext, whose whole job is to tell
// a literal in an INITIALIZER slot from one that is a declaration's NAME: both are
// KindNumericLiteral and only the parent decides.
var n = 1;
var s = "a";
var o = { 1: n };
(n);
