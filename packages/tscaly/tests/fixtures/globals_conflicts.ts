// Slice 104: the two reports initializeChecker makes on its own, and the one shape
// that must NOT report.
//
// `globalThis` is seeded into the table before anything is merged, so a SCRIPT
// declaring its own is the file-loop's first four lines; `undefined` is seeded
// AFTER the merge, so a file that already declared it takes the other branch of
// addUndefinedToGlobalsOrErrorOnRedeclaration. Both report TS2397 — at the
// DECLARATION, once per declaration.
//
// The interface is the exemption and it is why ast.IsTypeDeclaration is ported:
// `undefined` here is ONE symbol with two declarations, and only the non-type one
// is reported. TS2427 comes from elsewhere and is the control that the line was
// checked at all.
declare var undefined: number
interface undefined { a: number }
declare var globalThis: number
