// The third state of the tristate: PRESENT and DISABLED, which is not the same
// answer as ABSENT — absent falls through to the compiler option and this does
// not. A boolean field could not tell them apart, and under this harness both
// happen to be silent, so the distinction is gated by the code rather than by the
// output (§3.5j).
// @ts-nocheck
function f(a) { }
