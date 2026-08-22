// Slice 53. The one term of checkGrammarVariableDeclarationList this slice does
// NOT port — `if blockScopeFlags == AwaitUsing { return
// checkGrammarAwaitOrAwaitUsing(node) }` — and this unit is the whole of stage
// 1's witness that it is reached.
//
// ★★★ THE REFERENCE ANSWERS TS2853 HERE and our side answers the unported tag
// `check-grammar-await-or-await-using`, because the deferred function is a chapter
// of its own: the module kind, the file's implied node format,
// IsInTopLevelContext, IsEffectiveExternalModule and a related-info attachment.
// The tag is the unit's FIRST report, which is what makes this unit useful — in
// any file that also holds an ordinary declaration the walk reports first and
// shadows it (§3.5cw's shadowed-by-the-walk shape).
//
// ★★ AND THE DEFERRAL ANSWERS **TRUE**, so the block-scoped statement check below
// it does not run. That direction is deliberate: answering false could put a
// TS1156 where the reference has none, and an INVENTED line is the one thing
// diagcheck can fail on, while a missing one is permitted by construction.
await using d = null;
