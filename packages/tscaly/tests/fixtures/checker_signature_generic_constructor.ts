// A constructor's type parameters are the CLASS's local ones — allTypeParameters
// from outerTypeParameterCount to the trailing thisType — and not the
// declaration's own, which a constructor cannot have.
class Box<T> {
    constructor(value: T) {
        return;
    }
}
