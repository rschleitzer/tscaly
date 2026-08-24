// Slice 63. The fifth diagnostic of checkGrammarBreakOrContinueStatement, and the
// reason it cannot be reached.
//
// ★★★ NOTHING IN THIS PORT WALKS INTO A FUNCTION BODY. checkFunctionDeclaration
// reaches checkFunctionOrMethodDeclaration, which stops at
// `check-function-or-constructor-symbol` — several statements before
// `c.checkSourceElement(node.Body())` — and every other function-like container is
// an EXPRESSION (a function expression, an arrow) or a class member, neither of
// which is walked either. So the walk in checkGrammarBreakOrContinueStatement can
// never meet a function-like ancestor, and TS1107 is dead code that is nonetheless
// written at the reference's own line.
//
// ★★★ THIS IS NOT §3.5v's *uncovered*, and the distinction is the point of the
// fixture: no input can lift it, because what stands in the way is a report in
// another arm. The reference has BOTH lines below; we have neither, and the second
// one shows why — the whole `w:` statement is a WhileStatement, whose arm this slice
// deliberately does not port, so its body is not walked for a second, independent
// reason. controls-slice63.sh's g14 adds the function body walk as a PREMISE and
// turns the first line into a live report, which is what makes this a measurement
// rather than a claim.
function f() { break; }
w: while (1) { function inner() { break w; } }
