// slice 38 — HasDynamicName, and the LATE-BOUND half of the pass.
//
// `f[k] = 1` has a name the binder cannot spell: GetElementOrPropertyAccessName
// answers nothing for a non-literal subscript, so GetNonAssignedNameOfDeclaration
// falls back to the LEFT OPERAND — the element access itself — and IsDynamicName
// says yes. The node then gets an ANONYMOUS symbol under the internal `computed`
// name, and is additionally collected on ONE internal `assignment` symbol in f's
// exports, which is what addLateBoundAssignmentDeclarationToSymbol is for.
//
// Two dynamic assignments, so the `assignment` symbol is made once and carries
// two declarations — a plain append, not the append-if-unique
// addDeclarationToSymbol does. `f["s"]` beside them is NOT dynamic (the subscript
// is a literal, so the name is that literal) and declares an ordinary `s`.
//
// ★ This is also the fixture that retires the `dynamic-name-element-access`
// marker: until this slice IsDynamicName reported at its element-access arm, on
// the argument that no name could be an element access — which slice 37 made
// stale and this shape makes false.
declare const k: string;
function f() {}
f[k] = 1;
f[k] = 2;
f["s"] = 3;
