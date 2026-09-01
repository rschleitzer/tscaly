// Slice 116, and every line of it is here because a CONTROL came back UNGATED
// without it. The battery's first run gated 14 of 26 rows, and six of the twelve
// misses were not a property of the code at all — the fixtures reached the arm
// with no input that could tell a right answer from a wrong one.
//
// One construct per row: a PARENTHESIZED initializer (the evaluator's
// skipOuterExpressions), a number concatenated with a string (AnyToString on the
// number side), `-1 >>> 0` (the one shift whose left operand is unsigned),
// `4294967296 | 0` (ToInt32's modulus), `Infinity` and `NaN` as identifiers (the
// globals-identity arm), `1 << 33` (the shift count's `& 31`, and TS2764 with
// it), an enum member NAMED `NaN` (isNumericLiteralName's Infinity/NaN
// exception, which is what keeps it from being reported as a numeric name), a
// string member followed by one with no initializer (the auto-value going ABSENT
// rather than continuing), and an AMBIENT non-const enum whose members are
// COMPUTED rather than auto-numbered.
//
// ★ §3.5ap from the other side: a fixture that contains a construct is not a
// fixture that reaches it, and a control is what says which one you wrote.
enum P { A = (1 + 2), B = 1 + "x", C = -1 >>> 0, D = 4294967296 | 0, E = Infinity, F = NaN, G = 1 << 33 }
enum Q { NaN, Infinity = 2 }
enum R { A = "s", B }
declare enum Amb { X, Y }
declare let a: P.A;
declare let b: P.B;
declare let c: P.C;
declare let d: P.D;
declare let e: P.E;
declare let g: P.G;
declare let h: Q.NaN;
declare let i: R.A;
declare let j: Amb.X;
