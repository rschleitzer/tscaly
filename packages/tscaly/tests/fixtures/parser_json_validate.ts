// Slice 19 — validateJsonValue, the walk that makes a JSON document JSON after
// the ordinary expression grammar has already parsed it.
//
//   expression  a BinaryExpression value: parses, then 1328
//   plus        a PrefixUnaryExpression whose operator is not MINUS — the only
//               reader of the operator field this slice added to the node
//   negx        minus with a non-numeric operand: the other half of that test
//   array       the recursion, and the ORDER of two complaints inside one array
//   missing     ★ two diagnostics at the SAME position — the parser's 1109 and
//               the validator's 1328 — which is what the RAW append buys: the
//               ordinary reporting route would drop the second as a duplicate.
//               Its span is also inverted (6..5), because getErrorSpanForNode
//               skips trivia forward from a zero-width missing node's pos.
//   import      a dynamic import as a property VALUE, which sets a SOURCE flag
//               on the file node — the JSON path ORs source_flags exactly as the
//               other grammar does, and this is the only way to see it
// @Filename: expression.json
{"a": a + 1}
// @Filename: plus.json
{"a": +1}
// @Filename: negx.json
{"a": -x}
// @Filename: array.json
[1, 'a', {"b": c}]
// @Filename: missing.json
{"a": }
// @Filename: import.json
{"a": import("m")}
