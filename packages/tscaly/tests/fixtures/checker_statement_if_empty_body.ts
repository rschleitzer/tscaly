// Slice 63. checkIfStatement's own report, and the ORDER it is asked in.
//
// ★★ THE TEST IS ASKED AFTER THE THEN-BRANCH HAS BEEN WALKED, which is the
// reference's order: an EmptyStatement's own arm is
// checkGrammarStatementInAmbientContext, so the walk runs first and the TS1313
// second. Here that is invisible (nothing is ambient) and it is what
// checker_statement_ambient_context.d.ts measures.
//
// ★ The ELSE branch is walked too and an empty one is NOT reported — the
// reference asks the question of `data.ThenStatement` alone. Reading the test as
// "an empty branch" instead of "an empty THEN branch" would invent a diagnostic on
// the second line, which is the one thing diagcheck fails on.
if (x) ;
else ;
