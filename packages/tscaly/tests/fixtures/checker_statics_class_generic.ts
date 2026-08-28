// SLICE 87. InterfaceType.LocalTypeParameters()' first reader that is not a stop.
// The synthesized construct signature carries the class's OWN type parameters —
// allTypeParameters minus the outer ones and minus the trailing thisType — so this
// fixture answers `G 4 1 0 0` where the plain one answers `G 4 0 0 0`.
class C<T> {
    static a: string;
}
