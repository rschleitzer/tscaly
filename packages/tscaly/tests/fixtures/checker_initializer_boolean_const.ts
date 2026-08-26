// getWidenedLiteralTypeForInitializer's SHORT-CIRCUIT, which is the whole
// difference between `let` and `const` for a literal initializer: the Constant
// node flag returns the literal type unchanged, so this file does NOT reach the
// booleanType stop its `let` sibling stops at and runs on to
// `check-type-assignable-to` instead.
//
// * SO THE FILE IS THE NEGATIVE OF checker_initializer_boolean_widening.ts, and
// the pair is what makes the short-circuit measurable: break it and this file
// acquires the sibling's tag.
const cb = true;
