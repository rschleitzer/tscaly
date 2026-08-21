// slice 41 — the NULL containing class, which is the reference's own arm:
//
//     // we can get here in cases where there is already a parse error.
//     if containingClass == nil { return InternalSymbolNameMissing }
//
// A private name in an OBJECT LITERAL parses, so the binder declares a property
// whose containing class does not exist, and it is named `%FEmissing`.
//
// ★★ And it draws NO id, which the class below is here to prove: `D` is
// `%FE#1@#x`. The order matters — the object literal comes first in the file, so
// a port that asked for an id before testing for the class would number nothing
// and shift D to 2.
const o = { #z: 3 };

class D {
    #x = 1;
}
