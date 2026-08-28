// `private x` binds the parameter TWICE — once as a parameter and once as the
// class property the binder synthesises — so getSignatureFromDeclaration
// re-resolves the name in the parameter's own scope to recover the parameter
// symbol. The second constructor has no parameter property and takes the plain
// path.
class C {
    constructor(private x: number, y: string) {
        return;
    }
}
class D {
    constructor(x: number) {
        return;
    }
}
