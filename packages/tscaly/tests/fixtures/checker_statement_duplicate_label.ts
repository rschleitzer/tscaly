// Slice 63. checkLabeledStatement's duplicate-label walk.
//
// ★★ THE REPORT IS ON THE LABEL, NOT ON THE STATEMENT, and here the two spellings do
// NOT coincide — a LabeledStatement's error range is the whole `a: …` and the
// label's is one character. That is slice 62's span-table finding from the other
// side: there the two coincided and the control was ungated, here they differ and
// the control is red.
//
// ★ The walk stops at the first FUNCTION-LIKE ancestor, so the same label may be
// reused inside a nested function. There is no fixture for that half: a function
// body is not walked, so the stop is unobservable — see
// checker_statement_jump_crosses_function.ts.
a: a: while (1) { }
