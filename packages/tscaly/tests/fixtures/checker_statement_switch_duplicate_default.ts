// Slice 64. checkSwitchStatement's one grammar report and the walk that is worth
// more than it.
//
// ★★★ TS1113 IS A ONCE-BIT OVER THE CLAUSE LOOP, NOT A PER-CLAUSE TEST. The
// reference keeps two locals — the first default clause seen, and a flag set by the
// report — so three defaults produce ONE diagnostic, on the second. A port that
// counted the clauses would report on the third as well, and the third `default`
// below is here for exactly that row.
//
// ★★★ AND IT IS THE DIAGNOSTIC THAT CAME DUE ON A DEFERRAL TWO SLICES OLD. TS1113
// is a grammarErrorOnNode on a DEFAULT CLAUSE, and DefaultClause was one of the eight
// arms error_range_for_node reported `error-range-rescan` for — deferred in slice 45
// with the reason *no BINDER diagnostic can carry one of these kinds* and the
// prediction *the reader that earns them is the CHECKER … a case clause*. This is
// that reader. Without the arm the report is dropped silently, because
// grammar_error_on_node answers false and record_unported keeps the FIRST tag, which
// the `switch (1)` above has already spent on check-expression.
//
// ★★ THE SPAN IS `default:`, EIGHT CHARACTERS — trivia-skipped start to the first
// STATEMENT's Pos, which is BEFORE that statement's own leading trivia. Neither
// endpoint is a token boundary, so the arm needed the clause's statement list rather
// than a re-scan, and that list is the other half of this slice (statements_of had
// three of its four arms until now).
//
// ★★ THE SECOND SWITCH IS THE WALK. Its clause statements are checked because
// checkSwitchStatement calls checkSourceElements on each clause — a statement
// container this port had never entered, since statements_of had three of its four
// arms until this slice. The `break nosuch` inside a clause reports TS1116 from
// slice 63's arm, and it is the whole evidence that the walk happens.
switch (1) {
    default: break;
    default: break;
    default: break;
}
switch (2) {
    case 1: break nosuch;
    default: continue;
}
