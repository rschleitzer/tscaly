// Slice 95's generic half — getTypeFromClassOrInterfaceReference's non-empty
// LocalTypeParameters branch, which is where the type ARGUMENTS are read, the
// missing ones are filled from their defaults, and the reference type is interned
// by its argument list.
//
// ★ `Pair<string>` is the fill: the second parameter has a default, so
// getMinTypeArgumentCount answers 1 and fillMissingTypeArguments instantiates
// `number` into the second slot. The pin prints `Pair<string, number>` for it —
// the FILLED list and not the written one, which is the whole point of the branch.
declare namespace N {
    interface Box<T> { v: T; }
    interface Pair<A, B = number> { a: A; b: B; }
    class Holder<T> { v: T; }
    let a: Box<string>;
    let b: Pair<string>;
    let c: Pair<string, boolean>;
    let d: Holder<Box<number>>;
}
