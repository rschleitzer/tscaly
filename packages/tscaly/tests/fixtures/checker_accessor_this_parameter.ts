// A `this` parameter on each accessor: doesAccessorHaveCorrectParameterCount
// allows the arity ONE higher when the first parameter is `this`, and
// GetSetAccessorValueParameter then reads the SECOND one.
class C {
    get x(this: C): number { return 1; }
    set x(this: C, v: number) { }
}
