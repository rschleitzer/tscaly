// TS1053: a set accessor cannot have a rest parameter.
class C {
    set x(...a: number[]) { }
}
