// slice 38 — JSDeclarationKindObjectDefinePropertyValue, the second of the two
// kinds this slice binds and the one that is a CALL rather than an assignment.
//
// `Object.defineProperty(f, "a", …)` declares `a` on f exactly as `f.a = 1` does:
// same arm, same flags, and the name comes from the call's SECOND ARGUMENT
// (slice 37 ported that half of GetNonAssignedNameOfDeclaration for all five
// kinds). getParentOfPropertyAssignment reads the FIRST argument here where the
// binary shape reads `bin.Left.Expression()`.
//
// ★ Unlike the Property kind this one IS JavaScript-only —
// IsBindableObjectDefinePropertyCall is reached only under IsInJSFile — so the
// unit is a `.js` file, and the third line proves the merge with a plain
// assignment: both carry Assignment, so they are one symbol with two
// declarations.
// @Filename: defprop.js
function f() {}
Object.defineProperty(f, "a", { value: 1 });
f.a = 2;
Object.defineProperty(f, "b", { value: 3 });
