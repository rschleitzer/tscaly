// Slice 116: checkConstEnumAccess (TS2475). A CONST enum's object type is legal
// on the left of a property access, as the object of an index access, on the
// right of an import or export assignment, inside a `typeof` query and in an
// export specifier — and nowhere else.
//
// ★ The stop this replaces went from ONE unit to thirteen the moment the enum
// chapter let those units reach it, which is why it is in this slice and not a
// later one: a diagnostic that arrives later reads as a new bug (§3.5p).
//
// ★★ The report's SECOND half is not here and cannot be: it is behind
// `isolatedModules || verbatimModuleSyntax`, neither of which the oracle's stub
// program sets, and what it needs beyond the flag is a PROJECT REFERENCE.
//
// ★ Of the two illegal uses below, only `f(C)` reaches its report: the
// initializer of `let u = C` stops in the variable declaration's own chapter
// (get-resolved-symbol) before the expression is checked. diagcheck compares a
// SUBSEQUENCE, so the missing line is not a failure — it is the honest state of
// the port, and the line stays as the marker for the slice that closes it.
const enum C { A = 1, B = 2 }
declare let n: number;
n = C.A;
let t: typeof C;
n = C["B"];
declare function f(x: unknown): void;
f(C);
let u = C;
export { C };
