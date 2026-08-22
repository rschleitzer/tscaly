// Slice 52. The last two of the rest-parameter arm's four reports — an optional
// rest parameter and one with a default.
//
// ★★ THE OPTIONAL ONE REPORTS ON THE `?` AND THE INITIALIZER ONE ON THE NAME, and
// that asymmetry is the reference's: `grammarErrorOnNode(parameter.QuestionToken,
// …)` against `grammarErrorOnNode(parameter.Name(), …)`. Together with
// checker_function_rest_parameter_last.ts, which reports on the `...` token, this
// one arm has THREE different spans — and a port that picked one node for all of
// them can be right about at most one.
//
// ★ Both of these are the LAST parameter of their function, deliberately: the
// index test one line above them returns first otherwise, and then neither report
// is reached at all.
function f(...a = []) {}
function g(...b?: any[]) {}
