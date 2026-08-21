// slice 45 — a DECLARATION WITH NO NAME, and the span that only a re-scan can
// give it.
//
// `export default 0` and `export default function () {}` both declare `default`,
// so the second is a duplicate and the binder reports on BOTH declarations. The
// first is an ExportAssignment and its span is the node's own; the second is a
// FunctionDeclaration whose Name is nil, and GetErrorRangeForNode has no better
// node for it — so the span is GetRangeOfTokenAtPosition(file, node.Pos()), the
// FIRST TOKEN of the construct. That is `export`, six bytes: not the whole
// declaration, and not the `function` keyword either.
//
// ★ The leading comment is a second claim in the same unit. A node's pos is its
// FULL start, trivia included, and the re-scan starts by skipping that trivia —
// a port handing the raw pos to the diagnostic opens the span at the `/*`.
export default 0;
/* leading */ export default function () { }
