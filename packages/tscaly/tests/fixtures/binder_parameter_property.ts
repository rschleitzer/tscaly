// slice 39 — the parameter PROPERTY, plainest shape. `constructor(public a)`
// declares TWO symbols out of ONE node: the parameter, in the constructor's
// locals, and a class property of the same name, in the class symbol's MEMBERS.
//
// ★ The plain parameter beside it is the other half of the claim — without the
// modifier test every constructor parameter would declare a property, so `b` must
// appear in the locals table and NOWHERE else.
//
// ★★ The node's own symbol slot is the PROPERTY's, not the parameter's: the
// reference declares the parameter first and the property second, and
// addDeclarationToSymbol writes node.symbol at both. So the walk line for the
// parameter node names the member symbol, which is the one observable of the
// declaration ORDER.
class A {
    constructor(public a: number, b: string, private c: A) {}
}
