// SLICE 71's BIGINT arm across all four spellings, which is one arm in the
// checker and TWO conversions underneath it: the scanner's own
// `ParsePseudoBigInt` for a binary or octal specifier (set_bigint_token_value)
// and the checker's for everything else. Slice 44 left that routine as a
// STAND-IN and named this arm as the reader that would earn it.
//
// * The VALUES are not pinned here and cannot be: the tag is the same whatever
// the digits come out as. tests/litcheck.sh is where `0xff` is asserted to be
// `255n` — this file asserts only that all four spellings reach a type.
1n;
0xffn;
0XFFn;
0b101n;
0o777n;
1_000n;
0n;
0x0n;
