// ★★★ reportImplementationExpectedError's FIRST TWO LINES, and the only shape
// that reaches them: a function declaration whose name failed to parse. The
// parser supplies a MISSING identifier — a node with pos equal to end — and the
// reference says nothing at all about such a declaration rather than reporting at
// a point. Every other diagnostic this unit carries is the parser's.
function (a: string): void;
