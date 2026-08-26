// SLICE 72's THREE LIVE WIDENING ARMS, and the pair of `return t` paths beside
// them. `let` widens a FRESH literal type back to its base type and `const` does
// not, so the two halves of this file are the same expression under two
// declarations — which is the whole content of
// getWidenedLiteralTypeForInitializer's one bit.
//
// * WHAT THE FIXTURE PINS IS THE STOP, NOT THE TYPE. The declaration's type is
// invisible to every yardstick here: the T section carries only what the kind
// inventory admits, and a variable's own type would need getTypeOfNode's
// expression arm. What IS visible is that the unit runs PAST the initializer to
// `check-type-assignable-to` — which is the row this slice's 202 units mostly
// landed on — and the controls in tests/controls-slice72.sh are what read it.
let s = "a";
let n = 1;
let g = 1n;
let t = ``;
const cs = "a";
const cn = 1;
