// Slice 65. checkModuleDeclaration's tail, TS2434 — a namespace may merge with a
// class, and it must come AFTER it.
//
// ★★★ THE GUARD IS `len(symbol.Declarations) > 1`, so this needs the MERGE and not
// just the pair of names: the namespace and the class are one symbol here, which is
// what makes getFirstNonAmbientClassOrFunctionDeclaration find the class from the
// namespace's own symbol.
//
// ★★ THE NAMESPACE MUST BE INSTANTIATED, which is why its body declares a value.
// An empty `namespace N {}` is NonInstantiated, the ValueModule flag is absent, and
// the whole block this report sits in is skipped — that is the same term
// checker_collision_namespace_instantiated.ts measures one head earlier.
//
// ★ The file-crossing twin TS2433 is one `if` above and cannot fire here: a unit is
// one file, so both source files are the same node. The comparison is ported
// anyway — see Checker.source_file_of_node for why folding it to `true` would
// delete a condition rather than a body.
export {};
namespace N { export var x = 1; }
class N {}
