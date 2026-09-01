// Slice 115's ARRAY type node — getTypeFromArrayOrTupleTypeNode's array half, and
// the PRINTER that names it. `b` is the pin the printer's precedence widening
// exists for: an array's ELEMENT is emitted at TypePrecedencePostfix, so a union
// element is parenthesized where a union CONSTITUENT is not, and the one bit slice
// 111 used could not answer both questions.
declare namespace N {
    interface A { x: number; }
    let a: string[];
    let b: (A | null)[];
    let c: A[][];
    let d: readonly string[];
    let e: readonly (A | null)[];
    let f: never[];
    let g: (() => void)[];
    type Alias = string[];
    let h: Alias;
}
