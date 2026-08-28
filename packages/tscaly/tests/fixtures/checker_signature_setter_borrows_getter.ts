// The setter's parameter has no annotation, so its type is the GETTER's return
// type. Without the signature it was a stop, and with it the implicit-any report
// for `v` disappears — a LOSS, which only a pin over the diagnostics can see.
class C {
    get x(): number {
        return 1;
    }
    set x(v) {
    }
}
