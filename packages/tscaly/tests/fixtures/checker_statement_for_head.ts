// Slice 64. checkForStatement's two DELEGATED calls, which are its whole content —
// the arm has no report of its own — and the fixture exists because the corpus
// exercises neither of them.
//
// ★★★ THE TWO CALLS ARE NOT THE SAME CHECK AND ONLY ONE OF THEM IS THE GRAMMAR ONE.
// The head runs `checkGrammarVariableDeclarationList(init)` inside the ambient guard,
// and then `checkVariableDeclarationList(init)` unconditionally — and the second is a
// WALK, which reaches checkGrammarVariableDeclaration once per declaration. They
// report disjoint families: the LIST check owns the empty list (TS1123), the trailing
// comma and the `using` placements, while the per-DECLARATION check owns TS1155
// (*const declarations must be initialized*) and TS2480 (*let is not allowed as a name
// in let or const declarations*).
//
// ★★★ THE FIRST LINE IS THE ONLY ONE THAT GATES THE GRAMMAR CALL, and it took a
// battery row to find that out. controls-slice64.sh's g17 removes the delegated
// grammar call, and with only the last two lines present **nothing moved** — over
// 17 950 corpus units AND over this file, because the two diagnostics the file was
// written for come from the OTHER call. `for (var ;;)` is the separating input:
// an empty declaration list, TS1123, zero-width at the semicolon, and the list check
// is the only thing in the port that produces it. ★§3.5v's UNCOVERED, twice over —
// the corpus does not hold it and the first draft of this fixture did not either.
//
// ★ The last line is the negative: an ordinary `for` head must stay silent, or every
// row aimed at this arm would be gated by a report that fires on everything.
for (var ;;) { }
for (const c;;) { }
for (let let = 1;;) { }
for (let i = 0; i < 1; i++) { }
