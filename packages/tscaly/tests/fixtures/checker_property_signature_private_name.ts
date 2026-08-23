// Slice 62. checkPropertySignature's own one report — a `#name` outside a class body.
//
// ★★★ IT IS THE ONLY THING checkPropertySignature DOES BESIDES CALLING
// checkPropertyDeclaration, AND ITS TEST IS SYNTACTIC WHERE THE METHOD'S TWIN IS A
// WALK. A property signature can only sit in an interface, a type literal or a mapped
// type, so being a signature is already proof that there is no containing class;
// checkMethodDeclaration cannot argue that way — a method with a private name is
// legal in a class body — so it asks GetContainingClass instead. Two reports of the
// same diagnostic, two different questions, and
// checker_method_signature_private_name.ts is the other half.
//
// ★★★ THE REPORT IS WRITTEN ON THE PROPERTY AND COMES OUT ON THE NAME, and that is
// not the reporter's doing: `error_range_for_node` resolves a PropertySignature to
// its declaration NAME (it is one of the seventeen kinds in
// `error_range_uses_declaration_name`), so `error_on_node(node, …)` and
// `error_on_node(node.Name(), …)` are the SAME span here — controls-slice62.sh's g02
// is that row and it comes back ungated with the proof. ★A MethodSignature is NOT in
// that list, so the same two spellings differ at the method's twin report and g13 is
// RED. **The span of a diagnostic is decided by a table, not by the argument the
// reporter is handed**, and the two halves of one diagnostic can therefore disagree.
export {};
declare const a: { #x: number };
