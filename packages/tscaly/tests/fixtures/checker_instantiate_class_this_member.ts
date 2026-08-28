// SLICE 86. A member whose return annotation is `this` is NOT thisless, so the
// MapsThisOnly fast path does not take it and instantiateSymbol MINTS — the first
// transient symbol this port has ever made. Its type comes back through
// getTypeOfInstantiatedSymbol.
class C {
    [k: string]: any;
    self(): this {
        return this;
    }
}
