// Slice 19 — one unit per arm of parseJSONText's dispatch on the first token.
// The corpus reaches NONE of these: all 52 of its .json units are objects, so
// the switch's other five arms are carried entirely by this file.
//
//   str/num   the literal arm, taken only when the lookahead says the next token
//             is not a colon
//   true/false/null   the TOKEN-node arm: the keyword IS the value
//   neg       the minus arm's first branch, a PrefixUnaryExpression that
//             validateJsonValue then accepts because the operand is numeric
//   empty     the EOF arm, which builds an empty statement list and reads the
//             end-of-file token directly rather than expecting it
// @Filename: str.json
"hello"
// @Filename: num.json
42
// @Filename: true.json
true
// @Filename: false.json
false
// @Filename: null.json
null
// @Filename: neg.json
-1
// @Filename: empty.json
