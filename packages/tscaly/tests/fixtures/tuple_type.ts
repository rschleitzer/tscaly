// Slice 115's TUPLE type node — the synthesized generic interface, its `length`
// member and the printer's five element shapes.
//
// ★ `b`'s `length` is the union `1 | 2` and `e`'s is plain `number`: with a
// VARIABLE element the arity is not a finite set, which is the one place
// ElementFlagsVariable decides a TYPE rather than a shape.
declare namespace N {
    interface A { x: number; }
    let a: [string, number];
    let b: [string, number?];
    let c: [a: string, b?: number];
    let d: [];
    let e: [string, ...number[]];
    let f: [...names: string[]];
    let g: readonly [string, number];
    let h: [(A | null), A];
    let i: [[string], number];
}
