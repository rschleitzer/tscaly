// Slice 54. The binding-pattern refusal of a using declaration — TS1492.
//
// ★★★ ONLY THE `await using` SPELLING GETS HERE, AND THAT IS A FACT ABOUT THE
// PARSER RATHER THAN THE CHECKER. `using [a] = [1]` does not parse as a
// declaration at all: `using` followed by `[` stays an identifier, so the
// statement is an element access and the reference answers TS2304 on `using`
// with no TS1492 anywhere. Measured on the way in, which is why this file has one
// line and not two.
//
// ★★ THE UNIT'S TAG NAMES THE LIST'S TERM, NOT THE DECLARATION'S, and that is
// forced rather than chosen: `await using` also reaches
// checkGrammarVariableDeclarationList's deferred await term, which stands in
// front of the declaration walk and reports there. So the DIAGNOSTIC is this
// fixture's evidence and the tag is not — the two terms cannot be separated while
// `using [a]` refuses to parse.
//
// ★ The span is the declaration's NAME — the pattern — because
// error_range_for_node's declaration-name list carries VariableDeclaration; and
// the reference reports TS2853 on the top-level `await` beside it, from a
// dimension this port has none of.
await using { b } = { b: 1 };
