// Slice 48. The unit that measures the SORT, and it takes a specific shape to do
// it: TWO diagnostics from two different producers, discovered in the OPPOSITE
// order to the one they must be reported in.
//
//   checkGrammarSourceFile runs FIRST, before any statement, and finds the class
//   at the END of the file -> TS1046, at the later position.
//   checkSourceElements then reaches the `;` at the START -> TS1036, earlier.
//
// GetDiagnosticsForFile sorts before answering, so the reference prints TS1036
// first. A port that emitted in discovery order prints them the other way round
// — the same two lines, and wrong. ★ That is the only thing a one-element list
// cannot show, which is why the first draft of the slice-48 battery reported its
// sort control UNGATED and this fixture is the answer to it.
;
class C {}
