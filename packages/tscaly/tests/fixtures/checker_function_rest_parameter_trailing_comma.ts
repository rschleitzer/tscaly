// Slice 52. The trailing comma after a rest parameter, and the one call in
// checkGrammarParameterList whose RESULT IS DISCARDED.
//
// ★★★ THE SECOND FUNCTION IS THE WHOLE POINT: `...a?,` reports TWICE. The
// reference writes `c.checkGrammarForDisallowedTrailingComma(parameters, …)` as a
// statement of its own and then falls through to the question-mark test, so the
// comma's TS1013 and the optional's TS1047 both stand. Reading that call as a
// `return` — which the four reports around it are — would drop the second, and no
// fixture with a simple trailing comma can tell the two readings apart.
//
// ★ The message here is TS1013 rather than the plain trailing-comma one: the same
// helper takes the code as a parameter, because its two callers differ only in
// that.
function f(...a: any[],) {}
function g(...b?: any[],) {}
