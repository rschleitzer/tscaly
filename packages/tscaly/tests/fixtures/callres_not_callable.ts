// Slice 108. TS2348 — `Value of type '0' is not callable. Did you mean to include
// 'new'?`
//
// ★★★ IT IS THE ONE `numCallSignatures == 0` REPORT THIS PORT CAN REACH, and the
// reason is the SHORT CIRCUIT rather than the report: isUntypedFunctionCall's third
// disjunct needs `numConstructSignatures == 0`, so a type WITH a construct signature
// fails that conjunct before the `globalFunctionType` term — which is §3.11 — is
// ever asked. Its sibling TS2349 sits behind that term and has no input at all.
interface Ctor { new (x: number): object }
declare const k: Ctor;
k(1);
