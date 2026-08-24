// Slice 63. checkThrowStatement's report, which is about a token that is not there.
//
// ★★★ `throw` followed by a line break parses as a throw of a MISSING identifier —
// an Identifier node with empty text whose pos and end are the same number — and the
// diagnostic is placed at that position with LENGTH ZERO. That is why it goes
// through grammar_error_at_pos rather than through either node-shaped reporter, and
// why the fixture is worth having: the yardstick compares spans, so a port that
// rounded the span up to the `throw` keyword would be wrong in a way no counter
// moves for.
//
// ★ It must be at TOP LEVEL. A `throw` inside a function body is unreachable here,
// for the reason checker_statement_jump_crosses_function.ts records: nothing in this
// port walks into a function body.
throw
