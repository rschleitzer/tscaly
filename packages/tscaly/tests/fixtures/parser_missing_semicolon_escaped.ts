// slice 17: parseErrorForMissingSemicolonAfter reads the identifier NODE's
// text, which is the DECODED value. The name below decodes to `constx`, one
// insertion from `const`, so the diagnostic is
// Unknown_keyword_or_identifier_Did_you_mean_0 (1435). Read off the SOURCE —
// which is what this port did until the text was stored — the name is eleven
// bytes, no keyword survives the length filter, and the answer is
// Unexpected_keyword_or_identifier (1434). A wrong CODE, not a missing message
// argument.
//
// ★ The trailing `x` is what makes the line REACH the site (§3.5aa), and its
// absence is what a control caught: the error is reported about the statement
// a missing semicolon FOLLOWS, so a name written last is never the node the
// routine is handed. Without it the fixture matched and gated nothing.
\u0063onstx x
