// Slice 95's three arity diagnostics, and they are the slice's whole diagnostic
// product from the class/interface arm.
//
//   TS2314  Generic type '{0}' requires {1} type argument(s)   — a fixed arity
//   TS2707  ... requires between {1} and {2} type arguments    — with a default
//   TS2315  Type '{0}' is not generic                          — checkNoTypeArguments
//
// ★ The first two come out of ONE fork whose condition is
// `minTypeArgumentCount < len(typeParameters)`, i.e. *does any parameter have a
// default* — so `Box` and `Pair` are the two sides of one comparison rather than
// two unrelated reports.
declare namespace N {
    interface Box<T> { v: T; }
    interface Pair<A, B = number> { a: A; b: B; }
    interface Plain { p: number; }
    let a: Box;
    let b: Pair;
    let c: Box<string, number>;
    let d: Plain<string>;
}
