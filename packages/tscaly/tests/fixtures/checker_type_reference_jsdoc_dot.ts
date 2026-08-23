// Slice 61. checkTypeReferenceNode's JSDoc-dot report — the one place in this file
// that RE-SCANS the source for a token kind.
//
// ★★★ THE REFERENCE RECOGNISES `Foo.<T>` BY THE GAP. parseEntityName breaks out of
// its dotted loop when a `<` follows the dot and leaves the dot UNCONSUMED, so the
// type name ends before the type-argument list begins; the checker scans the token
// sitting in that gap and reports only when it is a DotToken. Anything else there
// — a comment, a stray token from a recovered parse — leaves the branch untaken,
// which is why the guard is a scan and not an arithmetic comparison.
//
// ★ The span is one character wide, at SkipTrivia of the type name's end, so it
// covers the dot alone and not the name or the brackets.
export {};
interface Box<T> { v: T }
declare const jsdocStyle: Box.<number>;
declare const plain: Box<number>;
