// Slice 105's diagnostic product from the REFERENCE side, and it is the half of
// the generic path that lands: the arity comparison reports while the
// instantiation behind it is a stop.
//
//   TS2314  Generic type '{0}' requires {1} type argument(s)     — G, both ways
//   TS2707  ... requires between {1} and {2} type arguments      — H, with a default
//   TS2315  Type '{0}' is not generic                            — P, checkNoTypeArguments
//
// ★ `a` is too FEW arguments and `d` too MANY, which is the one comparison in
// this chapter with two sides — a fixture carrying only one of them makes the
// other side's control ungatable.
//
// ★ `q` is the row that does NOT report: a generic alias whose arity is RIGHT
// reaches getTypeAliasInstantiation, which is this slice's stop. So the fixture
// carries both sides of the same comparison.
declare namespace N {
    type G<T> = T;
    type H<A, B = number> = A;
    type P = number;
    let a: G;
    let b: H;
    let c: P<string>;
    let d: G<string, number>;
    let q: G<string>;
}
