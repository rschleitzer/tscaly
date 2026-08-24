// Slice 63. checkWithStatement's unconditional report, and its two-node span.
//
// ★★★ EVERY `with` COLLECTS TS2410 — the checker does not support the construct at
// all — and the span is the HEAD alone: from the statement's trivia-skipped start to
// the POS of its body, i.e. `with (x)` including the closing parenthesis and
// excluding the block. No node has that span, which is what grammar_error_at_pos
// exists for and why this fixture is the second of its two witnesses.
//
// ★★ THE SECOND `with` IS INSIDE A `try`, and it is here to show the arm reached
// through another arm of the same slice rather than off the statement list. It is
// also the only route into a nested statement this slice has: a `with` inside a
// FUNCTION would not be reached at all.
//
// ★ This file is deliberately NOT a module. A module is strict, `with` is a parse
// error in strict mode (TS1101), and a parse diagnostic suppresses every grammar
// check in the file — so the module spelling of this fixture would measure the
// suppression instead of the report. That is also half of why TS1300 is unreachable;
// the other half is the function body.
with (x) { }
try { } finally { with (x) { } }
