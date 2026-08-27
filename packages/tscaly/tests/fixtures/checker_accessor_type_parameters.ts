// TS1094: an accessor cannot have type parameters.
class C {
    get x<T>(): number { return 1; }
}
