// The checker skeleton's own witness: a unit with NO statements.
//
// Its whole dump is one line — `T 1 <pos> <end> any`, the end-of-file token,
// whose type is errorType and whose printed form is `any`. That is the only shape
// slice 47 can answer, and it is not a degenerate case: it exercises the file-level
// check whole (checkGrammarSourceFile, the empty statement loop, checkDeferredNodes,
// checkUnusedRenamedBindingElements, produceDeferredDiagnostics), the type walk, the
// exclusion predicate, getTypeOfNode's fallthrough and the printer's `any` arm.
