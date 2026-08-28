// SLICE 87. The inheriting arm of the third branch — `maps.Clone(members)` plus
// addInheritedMembers over the base CONSTRUCTOR type's properties — is unreachable
// today, and this fixture is what says so from TWO sides. The base class B's own
// static side resolves normally; the DERIVED class C's is never asked for, because
// checkClassDeclaration stops at `class-extends-heritage-clause` before the walk
// reaches it. Even if it did arrive, getBaseConstructorTypeOfClass stops one call
// further on, at `is-constructor-type` — which is the wall slice 86 measured from
// resolveBaseTypesOfClass' side.
class B {
    static b: string;
}
class C extends B {
    static a: string;
}
