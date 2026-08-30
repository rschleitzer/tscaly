// Slice 102: The arithmetic and bitwise group — the boolean suggestion, the three
// result forks and the shift tail, one shape per line.
var mulLit = 1 * 2;
var divMixed = 1 / "x";
var subStr = "x" - 1;
var modAny: any = 1;
var modResult = modAny % modAny;
var bitBool = true & false;
var xorBool = true ^ false;
var orBool = true | false;
var bigMul = 1n * 2n;
var bigUnsigned = 1n >>> 1n;
var bigPow = 1n ** 2n;
var shiftBig = 1 << 40;
var shiftSmall = 1 << 3;
