// A constructor in a DERIVED class: the reference asks classDeclarationExtendsNull
// before the super-call block, and that is a type question.
class B { }
class C extends B {
    constructor() { super(); }
}
