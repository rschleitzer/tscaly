// Slice 54. The uninitialized-declaration fork, both of its reports and one of
// its negatives.
//
// ★★ THE ORDER OF THE TWO IS THE FIXTURE. A destructuring declaration with no
// initializer is refused BEFORE the keyword is looked at, so `var { p }` answers
// TS1182 and not TS1155 — and the `!ast.IsBindingPattern(node.Parent)` guard on
// that report is what keeps a NESTED pattern out of it, since a binding
// element's parent IS a pattern.
//
// ★ `using u` reaches TS1155 through the same switch as `const x`: the four
// block-scope keywords share one code, so `let` is the only one of them that is
// legally uninitialized.
const x;
using u;
var { p };
var [q];
let { r } = { r: 1 };
