// slice 42 — every this-container getThisClassAndSymbolTable answers for, in one
// class: the constructor, a property declaration's INITIALIZER, a method, a
// getter, a setter and a static block. Six kinds, six arms, and each one is a
// separate `if` in the ported function.
//
// ★★ A property declaration is a this-container only WHEN IT HAS AN INITIALIZER
// (upstream's ContainerFlags arm tests exactly that), so `d = this.e = 1` reaches
// the arm and a bare `f;` could not — the register would still be the constructor's
// or nothing at all.
//
// ★ The static block's assignment goes to a DIFFERENT table from all the others,
// which the next fixture is about.
// @Filename: thisctr.js
class C {
    d = (this.fromInitializer = 1);
    constructor() {
        this.fromCtor = 1;
    }
    m() {
        this.fromMethod = 1;
    }
    get g() {
        this.fromGetter = 1;
        return 1;
    }
    set g(v) {
        this.fromSetter = 1;
    }
    static {
        this.fromStaticBlock = 1;
    }
}
