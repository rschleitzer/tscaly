// Slice 115's QUICK TYPE — getReturnTypeOfSingleNonGenericSignature, the fast path
// getTypeOfExpression takes first, and the frontier's largest row by units for four
// slices. This is its POSITIVE case, and the only shape of the four that completes:
// the three that answer nil fall through to the ordinary dispatch, which stops, so
// they live in quick_call_fallthrough.ts with their tag as the witness.
declare namespace N {
    interface A { x: number; }
    declare function f(): A;
    let a = f();
}
