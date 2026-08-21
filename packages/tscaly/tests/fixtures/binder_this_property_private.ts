// slice 42 — the PRIVATE-name guard, the arm's second line: a left side whose
// name is a PrivateIdentifier returns before anything is declared.
//
// ★★ It is not an optimisation and it is not about JavaScript. `#x` is declared by
// the class body — slice 41 is what gives that declaration its name — so binding
// the assignment too would put a SECOND declaration on the class's own private
// member, or a symbol named `#x` beside it. The plain `this.b = 2` in the same
// constructor is the control: one member is declared here, not two.
// @Filename: thispriv.js
class C {
    #x;
    constructor() {
        this.#x = 1;
        this.b = 2;
    }
}
