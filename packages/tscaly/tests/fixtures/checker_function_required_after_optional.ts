// Slice 52. `A required parameter cannot follow an optional parameter`, whose
// condition is a piece of STATE carried across the loop.
//
// ★★★ THE THIRD FUNCTION IS THE MECHANISM AND IT REPORTS NOTHING. The test is
// `seenOptionalParameter && parameter.Initializer == nil`, so a parameter that
// follows an optional one is fine as long as it has a DEFAULT — it is not required
// either. A fixture with only the first two lines passes on a port that dropped
// the initializer test, which is the half that is not about the `?`.
//
// ★★ AND THE FLAG IS SET IN THE OPTIONAL ARM, NOT AT THE TOP OF THE LOOP, so the
// second function is the other negative: a required parameter BEFORE an optional
// one is the legal order and the state must not have been set yet.
function f(a?: number, b: number) {}
function g(a: number, b?: number) {}
function h(a?: number, b: number = 1) {}
