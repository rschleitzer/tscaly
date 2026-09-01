// Slice 116: the enum-literal table's NaN key, and it is one of TWO rules this
// port has for NaN — see literal_values_equal's header for the other, and why
// they disagree on purpose.
//
// ★★★ THE MEASUREMENT IS THAT `Y` PRINTS AS `NaNs.X`. Two members with the value
// NaN share ONE literal type here, because the table's comparison asks
// jsnum_is_nan on both sides — which is what upstream's separate
// `enumNaNLiteralTypes` map exists to achieve, a Go map lookup on NaN always
// missing. Written with plain bit equality the two would be different types and
// the second would print its own name, which is exactly what control g23 does.
//
// ★★★ AND THE TWO NaNs HAVE DIFFERENT PAYLOADS ON PURPOSE, which is what makes
// the row gate at all. `0 / 0` is the hardware's quiet NaN, 0x7FF8000000000000;
// the identifier `NaN` goes through jsnum_from_string, which answers Go's uvnan
// 0x7FF8000000000001. Written `Y = 0 / 0` the bits are EQUAL and plain equality
// answers the same thing the NaN rule does — the first draft of this file did
// exactly that and the control came back ungated.
enum NaNs { X = 0 / 0, Y = NaN, Z = 1 }
declare let x: NaNs.X;
declare let y: NaNs.Y;
declare let z: NaNs;
