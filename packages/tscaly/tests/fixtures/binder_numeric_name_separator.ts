// slice 44 — the numeric SEPARATOR, which the value does not have.
//
// `1_000` names the member `1000`. Upstream the `_` never reaches the value at
// all: scanNumberFragment builds the value out of the digit runs it collected, so
// tokenValue is already `1000` before jsnum sees it. This port hands over the
// SOURCE RANGE instead and lets decimal.set's own separator arm drop them — the
// two differ as strings in the three shapes the scanner's note lists and in none
// of them as a value, and this fixture is the shape where a port that did neither
// declares a member nobody wrote.
//
// ★ The separator is admitted in the fraction and in the exponent too, and the
// exponent one is the row that also crosses the arm that CONCATENATES: `1_0e1_0`
// is 10e10, the member `100000000000000`.
//
// ★★ A RADIX literal's separators are removed somewhere else entirely, and that
// is why `0x1_F` is here beside the decimals: the scanner builds `0x`+digits
// itself for the three radix arms and drops the `_` while it copies. Two removals
// in two routines for one rule, and each has a control of its own — because in
// each case the removal is the ONLY one there is. A `_` that got through answers
// NaN, from `isNumberRune` for a decimal and from the hex digit test for a radix
// literal; `decimal.set`'s own separator arm never sees one.
//
// ★ `1_000` and `1000` merge, and so do `0x1_F` and `31`, which is how the
// yardstick sees the removal rather than merely the name.
class S {
    1_000 = 1;
    1000 = 2;
    1_2.3_4 = 3;
    1_0e1_0 = 4;
    0x1_F = 5;
    31 = 6;
}
