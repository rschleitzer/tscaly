// Slice 102: The prefix unary expression — the two literal folds in front of the
// switch, then `+`, `-`, `~`, `!` and getUnaryResultType's bigint fork.
var negLit = -1;
var posLit = +2;
var negZero = -0;
var negBig = -1n;
var notTilde = ~5;
var notTrue = !true;
var notZero = !0;
var notStr = !"a";
var plusBig = +1n;
var negStr = -"a";
var negParenBig = -(1n);
var tildeParenBig = ~(1n);
