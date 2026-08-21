// slice 39 — the EXCLUDES, in all three of their directions, and they are the
// argument for declaring the property with SymbolFlagsPropertyExcludes rather
// than with something looser. PropertyExcludes is `Value & ^(Property |
// Accessor)`, i.e. every value meaning EXCEPT the two a property may share a
// name with.
//
// A: `Property` is not in it, so the declared member and the parameter property
// MERGE — one symbol, two declarations, no diagnostic.
//
// B: `Method` is, so the same shape over a method is a duplicate identifier,
// reported on BOTH names. The parameter property then gets a fresh symbol that
// the members table does not hold — the path declare_symbol's own comment
// describes.
//
// C: `Accessor` is not in it either, so a get accessor and a parameter property
// of one name merge into a symbol carrying GetAccessor AND Property.
class A {
    a: number;
    constructor(public a: number) {}
}
class B {
    m(): void {}
    constructor(public m: number) {}
}
class C {
    get g(): number { return 1; }
    constructor(public g: number) {}
}
