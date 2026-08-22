// Slice 53. The AMBIENT arm of checkGrammarVariableDeclarationList's using fork,
// both halves, in one unit.
//
// ★★★ THE FLAG IS ON THE DECLARATION LIST AND IT COMES FROM THE `declare` ABOVE
// IT, not from a modifier on the statement. `declare using x` is refused by
// checkGrammarModifiers first (TS1491) and never reaches this arm at all, so the
// only shape that gets here is a using declaration INSIDE an ambient container —
// which is why both lines sit in a `declare namespace` and not at file scope.
//
// ★★★ THE ORDER OF THE TWO ARMS IS WHAT THE SECOND LINE WITNESSES. `await using`
// also reaches checkGrammarAwaitOrAwaitUsing — the term this slice defers — but
// the ambient test stands in FRONT of it and returns, so the answer is TS1546 and
// not the deferred report. A port that put the await term first would tag this
// unit unported and print nothing, which a subsequence test cannot see: the pair
// is here because only the ORDER separates them.
declare namespace M { using c: any; }
declare namespace P { await using d: any; }
