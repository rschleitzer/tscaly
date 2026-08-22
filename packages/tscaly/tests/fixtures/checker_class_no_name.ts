// Slice 51. checkClassDeclaration's own prefix: the missing-name report, which is
// the only diagnostic the arm adds before it hands over to
// checkClassLikeDeclaration.
//
// ★★ THE PAIR IS THE TEST. Both classes are anonymous and only the first reports:
// the condition is `Name() == nil && !HasSyntacticModifier(node, Default)`, so
// `export default class {}` is the legal spelling and a bare `class {}` is not.
// A fixture with only the first would pass on a port that ignored the modifier.
//
// ★★★ THE SPAN IS THE FIRST TOKEN — grammarErrorOnFirstToken, a scan at the
// node's pos — AND NO FIXTURE CAN PROVE IT, which is worth knowing rather than
// discovering twice. What separates that reporter from grammarErrorOnNode is that
// the error RANGE finds a declaration's NAME and reports there; with no name it
// falls back to the token at the node's pos, i.e. to the same answer. This report
// fires only when the class has no name, so the two are provably indistinguishable
// here. Control f15 was written expecting RED and came back UNGATED with that
// proof; f20 gates the report on its CODE instead.
class {}
export default class {}
