// SLICE 79: the same report where the block-scoped declaration is a LOOP VARIABLE,
// which is the case the container walk answers by finding NOTHING.
//
// ★★ `for (let v of [])` puts `v` in a VariableDeclarationList whose parent is the
// ForOfStatement — not a VariableStatement — so `container` stays null,
// namesShareScope is false by the leading `container != nil` conjunct, and the
// report is reached along a path that never looks at a container KIND at all. The
// three kind arms and this one are therefore separable, which is what makes it a
// second fixture rather than a second copy of the first.
//
// * Transcribed from the reference's own conformance case for-of53.
for (let v of []) {
    var v;
}
