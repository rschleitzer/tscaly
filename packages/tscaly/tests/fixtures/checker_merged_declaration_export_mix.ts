// Slice 65. checkExportsOnMergedDeclarations' first report, TS2395, and it is the
// whole reason the function is a head of five arms rather than a check of one
// kind: `interface I {}` twice is ONE symbol with two declarations, and the rule
// is that they agree on being exported.
//
// ★★★ THE REPORT IS ON EVERY CONTRIBUTING DECLARATION, not on the pair, which is
// what the second loop is for — so two lines report and a third that agrees with
// neither accumulator does not.
//
// ★★ THE ONCE-GUARD IS A NODE IDENTITY TEST AND THIS FILE IS WHAT MEASURES IT.
// `GetDeclarationOfKind(symbol, node.Kind) != node` returns for every declaration
// but the first of its kind, so the pair below reports TWICE and not four times —
// once per declaration, from the one run that was allowed to happen.
export interface I {}
interface I {}
