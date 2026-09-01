// Slice 117 — a default value on a binding element, which is the branch that
// takes `undefined` out of the indexed access and unions the initializer in.
//
// ★★ THE TWO HALVES ARE DIFFERENT FUNCTIONS. With no annotation on the ROOT the
// element's type is `getUnionType(nonUndefined(T), typeof initializer)` widened
// from the initializer; with an annotation the initializer only STRIPS undefined
// and never widens the type. Both are written; `a` is the first and `b` the second.
declare const src: { a?: number; b?: number };
const { a = 1 } = src;
const { b = 2 }: { b?: number } = src;
