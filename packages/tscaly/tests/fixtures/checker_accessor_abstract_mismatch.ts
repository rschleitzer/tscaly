// TS2676: accessors must both be abstract or non-abstract. The report fires on
// BOTH names, once per pair.
abstract class C {
    abstract get x(): number;
    set x(v: number) { }
}
