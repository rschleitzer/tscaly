// Slice 19 — the error recovery, which is where the JSON grammar stops being a
// subset and starts being a parser.
//
//   multi     several top-level values: collected and wrapped in a SYNTHESIZED
//             ArrayLiteralExpression no bracket in the source produced, with
//             Unexpected_token reported once, after the FIRST value only
//   colon     a literal followed by a colon: the reference's `fallthrough`, so
//             the document is read as an object literal written without braces
//   minusx    the minus arm's second branch — `-` not followed by a number
//   minuskey  `-` followed by a number that turns out to be a KEY, which is the
//             second half of that lookahead and needs its own input
// @Filename: multi.json
1 2 3
// @Filename: colon.json
"a": 1
// @Filename: minusx.json
-x
// @Filename: minuskey.json
-1: 2
