// TS2379: a get accessor must be at least as accessible as the setter. Reported
// on both names, once per pair.
class C {
    private get x(): number { return 1; }
    set x(v: number) { }
}
