// Slice 51. checkGrammarHeritageClause's empty-list report — a ZERO-WIDTH span
// at the list's own start, which is the other span only the side table knows.
//
// ★★ THE TWO CLAUSES CARRY THE SAME CODE AND A DIFFERENT ARGUMENT, which is the
// argument-dropping decision made visible: upstream fills `{0} list cannot be
// empty` from scanner.TokenToString(clause.Token), so these two lines are two
// SENTENCES there and the same three numbers in the artifact. TokenToString stays
// unported for exactly that reason, and this is where the bill would be paid.
//
// ★ Both parse cleanly, which is what makes the report reachable at all: `{` is a
// terminator of the heritage-clause list, so the list ends empty without a parse
// diagnostic — and a parse diagnostic would suppress every grammar check in the
// file.
class A {}
interface I {}
class C extends {}
class D implements {}
