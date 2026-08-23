// Slice 56. checkGrammarBindingElement's FOURTH report — TS1186, a rest element
// with an initializer — and the only one of the four that reports at a span NO
// NODE has.
//
// ★★★ THE SPAN IS THE `=`, one character at `initializer.Pos() - 1`, which is
// why the reporter is grammarErrorAtPos (§3.5cw) and not grammarErrorOnNode. The
// reference says so in its own comment at the line: *Error on equals token which
// immediately precedes the initializer*. A port that reported on the node, or on
// the initializer, would put the span three characters away and diagcheck would
// see it — which is the whole reason this line is separate from the rest.
//
// ★★★ AND THE SUBTRACTION IS WHITESPACE-INDEPENDENT, WHICH IS NOT OBVIOUS AND IS
// WHY THE SECOND LINE EXISTS. `Pos()` is the FULL start — the END of the previous
// token, trivia included — and the previous token IS the `=`, so `Pos() - 1` is
// its last character no matter how much space follows it. The first guess was the
// opposite (that a run of spaces would drag the span onto one) and it is wrong;
// the second line's three spaces on each side report at the same offset relative
// to the `=` as the first line's one, and the third line's none does too.
//
// ★ The third block is the same report reached through a PARAMETER's pattern
// rather than through a variable declaration — the population slice 55's walk
// opened — and the last line is the negative half: an initializer on a NON-rest
// element, which is the ordinary destructuring default.
var { ...r = 1 } = o;
var [ ...q   =   2 ] = arr;
var { ...m=3 } = o;
function f({ ...p = 4 }) {}
var { n = 5 } = o;
