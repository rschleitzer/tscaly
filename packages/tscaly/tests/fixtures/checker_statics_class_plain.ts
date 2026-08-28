// SLICE 87. The static side of a class, at its plainest. resolveAnonymousType-
// Members' third branch: the exports table is the class's own (`a` plus the
// binder's `prototype`), there is no index symbol and no declared constructor, so
// the one signature is the SYNTHESIZED `new C(): C` getDefaultConstructSignatures
// mints. `G 4 0 0 0` — Construct, no type parameters, no parameters.
class C {
    static a: string;
}
