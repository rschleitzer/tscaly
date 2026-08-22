// Slice 53. checkGrammarForDisallowedTrailingComma on a variable declaration
// list — the first term of checkGrammarVariableDeclarationList, and the first
// reader of a DECLARATION list's own range.
//
// ★★★ THE SPAN IS `list.End() - 1`, WHICH IS A NUMBER ONLY THE SIDE TABLE HAS.
// `HasTrailingComma()` is `last.End() < list.End()`, and a declaration list's End
// is taken by parse_delimited_list BEFORE the terminator is consumed — so it
// covers the comma and the elements alone cannot deliver it. §3.5cv built that
// table's checker-side reader for the class heritage clause; this is the same
// mechanism one list along.
//
// ★★ THE SECOND STATEMENT IS THE GUARD, NOT DECORATION. Its list has no trailing
// comma, so `last.End() < list.End()` is false and nothing is reported — a port
// that read the row and skipped the comparison would light up here.
let a = 1, b = 2,;
let c = 3, d = 4;
