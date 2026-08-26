// ★★★ THE FIRST call site of reportImplementationExpectedError — the one INSIDE
// the loop — and the statement between the two overloads is the whole fixture.
// `previousDeclaration.End() != node.Pos()` is what "not immediately following"
// means, and a node's Pos() includes its leading trivia, so the intervening
// `var` is what pushes them apart. The report is on `g`'s FIRST declaration, not
// on the second.
function g(a: string): void;
var separator = 1;
function g(a: number): void;
function g(a: any): void { }
