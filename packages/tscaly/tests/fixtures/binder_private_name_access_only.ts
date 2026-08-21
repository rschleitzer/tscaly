// slice 41 — a READ is not a request. `A` mentions `#x` and declares nothing, so
// no declaration of A's ever reaches getDeclarationName's private arm and A
// draws no id at all: `B`'s member is `%FE#1@#x`.
//
// ★★★ This is the sharpest of the three laziness fixtures, because the class
// that must stay unnumbered is one that MENTIONS a private name. A port drawing
// the id anywhere but at the declaration — at the class, at the private
// identifier NODE, at the member access — numbers A and shifts B, and NOTHING
// ELSE in the dump moves: `#x` with no declaration is the checker's complaint,
// not the binder's, so this unit carries no bind diagnostic at all and the one
// wrong name is the whole visible difference.
class A {
    m() { return this.#x; }
}

class B {
    #x = 1;
}
