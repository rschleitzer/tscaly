// Slice 52. checkGrammarParameterList's first report: a rest parameter that is
// not the last one.
//
// ★★ THE SPAN IS THE `...` TOKEN, NOT THE PARAMETER — grammarErrorOnNode on
// `parameter.DotDotDotToken`. Reporting on the parameter instead is the same code
// three characters wide instead of at the right place, and only a fixture whose
// rest parameter has a name and a type annotation makes the two spans differ
// enough for the subsequence test to notice.
//
// ★ The second function is the negative half: a rest parameter that IS last must
// report nothing, which is what the index test buys. Without it a port that
// reported on every rest parameter would pass on the first line alone.
function f(...a: any[], b: number) {}
function g(b: number, ...a: any[]) {}
