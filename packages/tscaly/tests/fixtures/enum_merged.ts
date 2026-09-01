// Slice 116: checkEnumDeclaration's per-SYMBOL once-bit and the two reports
// behind it — every declaration of a merged enum must agree about `const`
// (TS2473), and only one of them may leave its first member without a value
// (TS2432).
//
// ★★ THE ONCE-BIT IS WHAT THIS FILE MEASURES, not the reports: both arms walk
// `symbol.Declarations`, so without it the second declaration reports the same
// pair a second time — and diagcheck compares a SUBSEQUENCE, where a duplicate
// line is a failure. The empty enum is here for getDeclaredTypeOfEnum's other
// exit: no member types at all, so the declared type is a computed enum type.
enum M { A = 1 }
const enum M { B = 2 }
enum N { A }
enum N { B }
enum P { X = 1, Y }
enum P { Z }
enum Q { }
declare let m: M;
declare let n: N.B;
declare let p: P;
