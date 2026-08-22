// Slice 51. checkGrammarTypeParameterList — the SECOND half of
// checkGrammarClassLikeDeclaration, and the first reader in this package of a
// list's own RANGE.
//
// ★★★ IT IS WHY §3.5bq's SIDE TABLE HAD TO TRAVEL ON THE TREE. The span is
// `list.Pos()-len("<")` to `SkipTrivia(text, list.End())+len(">")`, and neither
// end is derivable from the elements: an EMPTY list has none. The table was a
// Parser field while the parser was its only reader; a Checker holds no Parser,
// so it is handed over on the SourceFile beside the two diagnostic lists.
//
// ★★ THE SECOND CLASS IS THE TRIVIA SKIP'S OWN GATE. A bracketed list's end is
// the FULL START of the closing bracket, so with a comment in between it points
// at the comment and the report would be TWO characters wide instead of eleven.
// Nothing but a fixture with trivia there can tell the two spellings apart.
//
// ★ The third class must report NOTHING: the check fires on a list that exists
// and is empty, and a one-parameter list is neither.
class C<> {}
class D< /* c */ > {}
class E<T> {}
