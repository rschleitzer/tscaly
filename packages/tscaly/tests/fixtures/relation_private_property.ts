// propertyRelatedTo's first visibility arm: a private property is compatible only
// with the SAME declaration. Two classes each declaring `p` privately are not
// related however identical they look, and the unit COMPLETES with TS2322 —
// the ONE diagnostic, because the reference's own message here is a chain LINK
// and the head is reportRelationError's.
class A { private p: number = 1; }
class B { private p: number = 1; }
declare let a: A;
declare let b: B;
a = b;
