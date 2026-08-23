// Slice 57. The `if !c.checkGrammarModifiers(node)` that guards
// checkGrammarInterfaceDeclaration, and the shape that makes the guard visible.
//
// ★★★ ONE INTERFACE CARRIES BOTH FAULTS. `private` is illegal on a top-level
// interface and the two `extends` clauses are illegal on any — and the reference
// reports only the FIRST, because checkGrammarModifiers answers true and the
// heritage walk never runs. A port that called the heritage check
// unconditionally would print a second line the reference does not have, which
// is exactly what diagcheck's subsequence relation refuses.
//
// ★ The second interface is the same duplicate `extends` with NO modifier, so
// the heritage report is present on it. Without that line the fixture would
// pass against a port that had lost the heritage check altogether.
interface A {}
interface B {}
private interface C extends A extends B {}
interface D extends A extends B {}
