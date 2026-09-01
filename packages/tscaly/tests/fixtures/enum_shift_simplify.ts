// Slice 116: the shift-simplification report (TS2764), which is checkBinaryLike
// Expression's tail and was a stop until the constant evaluator existed — its
// whole content is `evaluate(right, right)` and a magnitude test.
//
// ★ It is `errorOrSuggestion`, and the bool that picks between the two is
// whether the shift sits in an ENUM MEMBER. A suggestion never reaches the C
// section, so this file's three lines are the only shape of it the yardstick can
// see at all.
enum Sh { A = 1 << 33, B = 2 >> 40, C = 4 >>> 32 }
declare let a: Sh.A;
