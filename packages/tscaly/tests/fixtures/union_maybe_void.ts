// maybeTypeOfKind's union recursion, which slice 94 restored: the guard of
// checkAllCodePathsInNonVoidFunctionReturnOrThrow is
// `maybeTypeOfKind(t, Void) || t.flags&(Any|Undefined)`, so a return type that
// CONTAINS void needs no return statement. With the recursion missing -- it was
// left out on a containment proof that the union chapter invalidated -- every one
// of these invented a TS2355. Three units of 18 249 at stage 2 and none of the
// 1 479 at stage 1 found it; this is the reduction.
export function a(): number | void {}
export function b(): void | number {}
export function c(): string | undefined {}
export function d(): number | any {}
export function e(): string | number { return "x"; }
