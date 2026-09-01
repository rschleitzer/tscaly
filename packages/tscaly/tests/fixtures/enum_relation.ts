// Slice 116: the enum arms of isSimpleTypeRelatedTo — `number` against an enum
// type, an enum against `number`, a numeric literal against an enum literal with
// a matching value (the reference's own "bit-flag purposes" rule), and two
// same-shaped enums that are NOT related because their symbols differ.
//
// ★ isEnumTypeRelatedTo's expensive half — the property walk over two merged
// enums of the same NAME — has no input here and cannot have one in a single
// unit: two declarations of one name in one file are one symbol, which the
// function answers TRUE for on its first line.
enum E { A = 1, B = 2 }
enum F { A = 1 }
declare let n: number;
declare let e: E;
declare let a: E.A;
n = e;
e = 1;
a = E.A;
e = F.A;
let x: E.A = 1;
let y: number = E.B;
