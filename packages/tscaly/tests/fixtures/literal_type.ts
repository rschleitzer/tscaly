// Slice 115's LITERAL type node — the largest single arm of getTypeFromTypeNode by
// units. ★`f` is the arm that runs BEFORE the memo: `null` as a literal type node
// is nullType, which no other arm of that table would give it.
declare namespace N {
    let a: "x";
    let b: 0;
    let c: -1;
    let d: true;
    let e: 1n;
    let f: null;
    let g: "x" | "y";
    let h: readonly 0[];
}
