// Slice 115's TYPE OPERATOR arms. ★`b` is the readonly arm's whole content —
// `readonly T` denotes exactly `T`, and the readonly-ness is read off the PARENT by
// getArrayOrTupleTargetType — while `c`'s operand is not the symbol keyword, so the
// unique arm answers errorType rather than reporting.
declare namespace N {
    let a: readonly string[];
    let b: readonly [string];
    let c: unique number;
}
