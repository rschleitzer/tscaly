// Slice 62. checkMethodDeclaration's private-name report, whose test is an ANCESTOR
// WALK where the property signature's twin is a kind test.
//
// ★★★ THE DIFFERENCE IS NOT STYLE. A method with a `#name` is LEGAL in a class body,
// so the reference cannot decide the question from the node's own kind and asks
// `GetContainingClass(node) == nil` instead — which is why this slice ports a walk
// for one report. checker_property_signature_private_name.ts is the other half of
// the pair: the same diagnostic, from a test that needs no walk at all.
export {};
declare const a: { #m(): void };
