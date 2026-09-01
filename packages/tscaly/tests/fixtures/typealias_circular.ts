// Slice 105's diagnostic product from the declared-type side: TS2456, and it is
// the reason the resolution stack gets its DeclaredType arm.
//
//   type A = A            the one-frame cycle
//   type B = C; type C = B   the two-frame one, which is what proves the search
//                            walks the stack rather than testing the top of it
//
// ★ The error node is `declaration.Name()`, not the declaration — and the two
// turn out to be the same SPAN, because the reference's own error() narrows a
// named declaration to its name anyway. The control that drops the fallback is
// what says so.
//
// ★★ `x2` IS THE MEMO'S INSTRUMENT. The report is made by
// getDeclaredTypeOfTypeAlias, so an alias referenced ONCE reports once whether or
// not links.declaredType is written; it takes a SECOND reference from outside the
// cycle for a missing memo to re-enter the body and report a fourth time. A memo
// row with no second reader measures nothing.
type A = A;
type B = C;
type C = B;
let x: A;
let y: B;
let x2: A;
