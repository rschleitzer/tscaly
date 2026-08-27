// SLICE 79: THE REPORT THE NAME RESOLVER EXISTS FOR — TS2481, and the shortest
// shape that reaches it.
//
// A `var` hoists to the enclosing function or file scope while a `let` binds to its
// block, so the two are not a duplicate to the binder; what the checker has to say
// is that the `var`'s WRITE would land on the block-scoped value. Answering it needs
// the scope chain: from the `var` declaration up through the inner block, which has
// no locals of its own, to the outer one, whose locals hold the `let`.
//
// ★ The container walk then decides the message. Here the `let`'s
// VariableDeclarationList sits in a VariableStatement whose parent is a BLOCK whose
// own parent is the SOURCE FILE — not function-like — so the two names do NOT share
// a scope after hoisting and the report stands.
//
// * No function wrapper, deliberately: with one, the unit's first stop would be
// `get-return-type-from-annotation` and the file would pin that row instead of this
// mechanism (slice 72's one-gate-per-file rule). As written the CHECK COMPLETES and
// the only stop is the dump walk's `type-of-node`.
{
    let x;
    {
        var x;
    }
}
