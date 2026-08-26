// checkGrammarNumericLiteral, all three of its exits, and NONE of them can be
// seen in a C section: its report is a SUGGESTION (TS80008, CategorySuggestion),
// and GetDiagnostics does not read that list. The file is here because the arm
// runs the check BEFORE the type — so the tag on every line below is
// `get-number-literal-type` and never a grammar row — and because the two texts
// the function reads are different texts:
//
//   the third literal's `node.Text` is the scanner's cooked `1.1e21`, which
//   CONTAINS a `.` the source does not, so asking the cooked text for the
//   fractional test would return early on the one literal that must be reported.
//
// ★ The witness for the reported case is a CONTROL, not this file: g-rows patch
// the sink to write into the diagnostic list and diagcheck goes red on the
// invented line, which proves both that the site runs and that routing it to the
// C section would be wrong.
9007199254740991;
9007199254740993;
1.5;
2e54;
1100000000000000000000;
