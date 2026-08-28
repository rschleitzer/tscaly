// TS1318: an abstract accessor cannot have an implementation.
abstract class C {
    abstract get x(): number { return 1; }
}
