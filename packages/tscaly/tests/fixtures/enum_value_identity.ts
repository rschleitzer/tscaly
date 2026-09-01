// Slice 116, and it is the fixture that answers a question the battery asked:
// HOW DOES AN ENUM MEMBER'S VALUE BECOME VISIBLE TO A TYPE DUMP AT ALL?
//
// ★★★ IT DOES NOT, DIRECTLY. `E.A` prints as `E.A` whatever its value is, so
// five of the battery's rows — ToInt32's wrap, the unsigned shift, the number
// stringified into a concatenation, the Infinity identity and the ambient
// computed member — came back UNGATED against fixtures that CONTAINED every one
// of those constructs. What makes a value visible is TYPE IDENTITY: two members
// of one enum whose values are EQUAL share a single literal type, and the second
// one prints the FIRST one's name. So each pair below is one arm, written as a
// computed value beside the literal it must come out equal to.
//
//   Wrap    3000000000 | 0 is -1294967296, and 1 << 31 is -2147483648
//   Shift   -1 >>> 0 is 4294967295
//   Concat  1 + "x" is "1x"            Global  Infinity is 1 / 0
//   Ambient a member with no initializer in a `declare enum` is COMPUTED, so it
//           does NOT continue the numbering and Z keeps a type of its own
//
// ★ Read the expected dump as the point of the file: `Wrap.B` prints as `Wrap.A`,
// and `Amb.Z` prints as `Amb.Z`.
//
// ★★ THE WRAP LINE TOOK TWO TRIES AND THE FIRST ONE MEASURED NOTHING. It was
// `4294967296 | 0`, whose answer is 0 with the int32 wrap and 0 without it —
// `fmod(x, 2^32)` has already done the work there, and the wrap only shows on a
// value whose remainder lands at or above 2^31. **A control aimed at a
// transformation needs an input the transformation MOVES.**
enum Wrap { A = 3000000000 | 0, B = -1294967296, C = 1 << 31, D = -2147483648 }
enum Shift { A = -1 >>> 0, B = 4294967295 }
enum Concat { A = 1 + "x", B = "1x" }
enum Global { A = Infinity, B = 1 / 0 }
declare enum Amb { X = 0, Y, Z = 1 }
declare let a: Wrap.B;
declare let a2: Wrap.D;
declare let b: Shift.B;
declare let c: Concat.B;
declare let d: Global.B;
declare let e: Amb.Z;
