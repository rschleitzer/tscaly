// Slice 108. TS2351 — `This expression is not constructable`, which is
// invocationErrorDetails reached from resolveNewExpression's tail.
//
// ★★★ THE `new` SIDE REACHES invocationError WITHOUT PASSING isUntypedFunctionCall,
// which is why TS2351 has input where its call-side twin TS2349 does not:
// resolveNewExpression asks isTypeAny, then the construct signatures, then the call
// signatures, and falls out of the bottom — no lib type anywhere on that path.
//
// ★★ THE SPAN IS THE CALLEE'S AND NOT THE `new` EXPRESSION'S, which is the half of
// invocationErrorDetails this port has to get right: the diagnostic is built for
// `errorTarget`, and every chain link keeps that loc.
declare const notNew: { a: number };
new notNew();
