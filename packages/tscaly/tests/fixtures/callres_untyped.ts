// Slice 108. TS2347 — `Untyped function calls may not accept type arguments`, on
// isUntypedFunctionCall's FIRST disjunct, the only one of the four with input at
// stage 1.
declare const anyf: any;
anyf<number>(1);
