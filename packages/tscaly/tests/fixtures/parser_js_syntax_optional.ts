// Slice 24 — the QUESTION-TOKEN arm. `?` is a modifier in TypeScript and the
// reference reports it at the token's own range on three hosts: a parameter, a
// property declaration and a method declaration.
//
// ★ The `!` on a property is deliberately here too and must produce NOTHING
// from this arm: it lands in the SAME postfix slot, which is why the reference
// tests IsQuestionToken rather than just reading the slot. Its own diagnostic
// comes from elsewhere and is not a JS-syntax one.
// @Filename: optional.js
function f(a?) {}

class C {
    p?;
    q!;
    m?() {}
}
