// Slice 55. checkParameter's four-term conjunction: NO initializer, a `?`, a
// BINDING PATTERN for a name, and a containing function that HAS a body.
//
// ★★ FOUR NEGATIVE LINES, ONE PER TERM, because the report is a conjunction and a
// fixture with only the positive line cannot say which term is load-bearing. `p`
// drops the pattern (an optional identifier parameter is ordinary), `q` drops the
// `?`, `r` drops the body — an overload signature may take an optional binding
// pattern, which is what the diagnostic's own wording says (*in an implementation
// signature*) — and `s` drops the initializer test.
//
// ★★ `s` IS ALSO A LINE THIS PORT ALREADY REPORTS ON, from one slice back:
// checkGrammarParameterList answers TS1015 for a parameter carrying both a `?`
// and an initializer. So the negative half of the initializer term is not a
// silent line, it is a line with the OTHER code — which is a stronger negative
// than silence, because a port that dropped the term would print two diagnostics
// where the reference prints one.
//
// ★ The body test here is the plain `fn.Body() != nil`, not NodeIsMissing —
// four lines above it in the reference the same question is asked the other way
// (checkVariableLikeDeclaration's TS2371), and the port transcribes both rather
// than unifying them. No unit separates the two spellings, which is why the
// difference is written down instead of tested.
function bad({a}?: any) {}
function p(a?: any) {}
function q({a}: any) {}
function r({a}?: any);
function r(x?: any) {}
function s({a}?: any = {}) {}
