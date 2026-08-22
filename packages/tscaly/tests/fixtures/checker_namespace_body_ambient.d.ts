// Slice 50. The block arm's recursion, as the smallest thing that produces a
// diagnostic THROUGH it: one statement inside a namespace body of a declaration
// file, answering the TS1036 that checkGrammarStatementInAmbientContext reports
// for a statement in an ambient context.
//
// ★★ EVERY LINE OF THE PATH IS THIS SLICE'S. checkModuleDeclaration ->
// checkSourceElement(body) -> the ModuleBlock arm -> checkBlock ->
// checkSourceElements -> the EmptyStatement arm. Only the last of those existed
// before, which is why slice 48's own once-bit fixture had to put its statements
// at the top level of the file.
//
// ★ The once-bit is on the containing BLOCK, and here that block is the
// ModuleBlock rather than the SourceFile — so this also pins that the bit is read
// off the parent and not off the file.
declare namespace N { ; }
