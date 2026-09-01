// Slice 108. A REST parameter — and the fixture's finding is that the pair
// getNonArrayRestType / getEffectiveRestType has NO INPUT, for a reason one chapter
// above itself.
//
// ★★★ THE WALL IS THE ARRAY TYPE NODE AND NOT THE REST PARAMETER. `...rest: number[]`
// cannot be TYPED at all — `get-type-from-type-node 189` is the ArrayType node, which
// is createArrayType over `globalArrayType`, §3.11 — so the signature never carries a
// rest type for getEffectiveRestType to read, and the `is-array-type` and
// `any-array-type` rows this slice writes stand at ZERO. A tuple rest is no way round
// it either: nothing in this port mints a tuple.
//
// ★★ IT IS KEPT ANYWAY, because a fixture that gates nothing is invisible until a
// control aims at one (§3.5ap) — and two of this slice's controls aim here, both
// predicting the silence.
function f(a: number, ...rest: number[]): void {}
f(1);
f(1, 2, 3);
