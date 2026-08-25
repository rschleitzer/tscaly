// The 25-unit shape: an interface WITH an extends clause. isThislessInterface has
// to resolve the base name to decide whether the base is an interface and whether
// it has a `this` type, and resolveEntityName is the first name resolution this
// port owes — so the arm stops there.
//
// ★ The DERIVED interface is written FIRST on purpose. record_unported is
// first-wins, so a base declared above it would report `get-base-types` and this
// fixture would pin a path it does not exercise.
interface Derived extends Base {
    b: number;
}
interface Base {
    a: string;
}
