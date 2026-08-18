// Slice 19 — isDoubleQuotedString, which has two clauses and therefore needs
// three inputs:
//
//   key     a single-quoted KEY   — the SingleQuote token flag, stored on the
//                                   literal node for this one reader
//   value   a single-quoted VALUE — the same flag reached through the value arm
//   ident   an identifier key     — the KIND clause: a node that is not a string
//                                   literal at all is not a double-quoted string
//                                   either, which is how `{a: 1}` gets 1327
// @Filename: key.json
{'a': 1}
// @Filename: value.json
{"a": 'b'}
// @Filename: ident.json
{a: 1}
