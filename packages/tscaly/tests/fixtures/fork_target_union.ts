// Slice 103: The TARGET-union arm of unionOrIntersectionRelatedTo — the one arm
// the corpus takes, and the shape checkArithmeticOperandType makes every time.
var toUnionOk: number | string = 1;
var toUnionNo: number | string = true;
var toUnionSelf: number | string = "s";
var toUnionWide: number | string | boolean | object | symbol = 1;
var arithLit = 1 * 2;
var arithBig = 3n * 4n;
var arithBool = true & 1;
