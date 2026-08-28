// SLICE 85. getMembersOfSymbol's late-binding fork. A computed member name is
// filed by the binder under its internal `computed` name, which is the marker
// this port can ask for exactly — and the answer decides whether the members
// table is the one the reference would build.
declare const key: unique symbol;
interface I {
    [key]: string;
}
