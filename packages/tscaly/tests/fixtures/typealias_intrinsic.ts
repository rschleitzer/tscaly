// Slice 105's one arm whose input lives in lib.es5.d.ts: `t == intrinsicMarkerType
// && symbol.Name == "BuiltinIteratorReturn"`. The `intrinsic` keyword is a type
// node this port already answers, so the arm is reachable from a fixture even
// though the name it tests for is the lib's — and the fixture is here because an
// arm nothing can enter and an arm that answers wrongly look the same otherwise.
//
// ★★ THE ARM IS MADE OBSERVABLE BY A COMPARISON RATHER THAN BY A NAME. The
// checker yardstick cannot print either type (the dump walk stops one arm up), so
// the fixture ASSIGNS: `undefined` is not assignable to `number` and the intrinsic
// marker is not either, but the two answers arrive through different types, and
// the RELGATE's checksum carries the flag words that tell them apart.
//
// ★ `strictBuiltinIteratorReturn` is a strict-FAMILY option and unset here, so the
// answer is `undefined` and NOT `any`; `Other` is the control that keeps the
// intrinsic marker itself, and the TS2795 on it is the reference's own rule that
// only a compiler-provided name may use the keyword.
type BuiltinIteratorReturn = intrinsic;
type Other = intrinsic;
declare let a: BuiltinIteratorReturn;
declare let b: Other;
declare let n: number;
declare let u: undefined;
function f(): void {
    let p: number = a;
    let q: number = b;
}
