// Slice 49. reportObviousDecoratorErrors, which runs BEFORE anything else in
// checkGrammarModifiers and reports TS1206 at the decorator's own first token.
//
// ★★ ALL FIVE KINDS THIS SLICE'S ARMS REACH ARE ON ast.CanHaveIllegalDecorators,
// so a decorator on any of them is caught here and the loop's whole decorator
// branch — NodeCanBeDecorated, the leading/trailing chunks, sawExportBeforeDecorators
// — is unreachable from these arms. That branch is ported anyway because
// checkGrammarModifiers is one function, and it becomes live with the class and
// function arms; this fixture is what measures the half that IS reachable.
//
// ★ The span is the `@`, not the decorator expression and not the statement:
// grammarErrorOnFirstToken SCANS at the node's pos.
@dec var a: number;
