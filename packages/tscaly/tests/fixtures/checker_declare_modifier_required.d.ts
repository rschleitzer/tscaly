// Slice 48. An AMBIENT unit whose FIRST top-level element is a declaration with
// no `declare`, `export` or `default` modifier — checkGrammarSourceFile's second
// half, which slice 47 deferred on ast.IsDeclarationNode alone. The reference
// answers TS1046 at the first TOKEN of the declaration (a scan, not the node's
// own pos, which is why the span is worth a fixture of its own).
//
// The three shapes below are the three the walk can distinguish:
//
//   `class C {}`      a declaration node with no exempting modifier -> TS1046
//   `interface I {}`  a kind on the EXEMPT list -> silent, even though it is a
//                     declaration node and carries no modifier either
//   `declare const c` a declaration node with ModifierFlagsAmbient -> silent
//
// ★ The walk returns on the FIRST element that reports, so the class has to come
// first for the other two to be saying anything: what they show is that the walk
// got past them.
interface I {}
declare const c: number;
class C {}
