// slice 42 — isReplaceableByMethod, FIRST arm: the constructor property arrives
// SECOND and loses immediately. `this.m = this.m.bind(this)` is the JavaScript
// pattern the flag exists for — rebinding a prototype method onto the instance —
// and it must not be a second declaration of `m`, let alone a duplicate.
//
// ★★★ The observable is an ABSENCE with a witness: `m` is one symbol with ONE
// declaration, the method's, and the assignment contributes nothing. The arm sits
// AHEAD of the excludes test in the reference, so without it this pair would
// report a duplicate identifier instead — which is why the dump's empty
// diagnostic section is part of what this fixture pins.
//
// ★ The method is written BEFORE the constructor deliberately: class members bind
// in source order, so this is the order that puts the method's symbol in the table
// first. The reverse order is the OTHER arm, and its own fixture.
// @Filename: thisrepl1.js
class C {
    m() {
        return 1;
    }
    constructor() {
        this.m = this.m.bind(this);
    }
}
