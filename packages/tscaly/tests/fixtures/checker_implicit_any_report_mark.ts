// ★★★ THE FIXTURE FOR THE UNPORTED *MARK*, and it gates the one defect this slice
// had to build twice before it was right. getTypeForVariableLikeDeclaration
// answers nil BOTH for "nothing can be inferred" — which the widener turns into
// `any` plus a diagnostic — and for a stop. The unit's unported FLAG cannot tell
// the two apart once anything has already reported, because record_unported is
// first-wins and the statement walk deliberately continues.
//
// So the file is three statements in this order:
//
//   1. a construct that STOPS       (the optional property needs getOptionalType)
//   2. a const with an initializer  (a stop of its own — must report NOTHING;
//                                    with a flag comparison it invents a TS7005)
//   3. an ambient var               (must still report its TS7005)
//
// With an absolute is_unported() test, line 3 is silent. With a before/after test
// on the FLAG, line 2 invents a diagnostic. Only the monotone report COUNT gives
// both answers, and this file is red under either mistake.
type Q = { y?: string };
const c = 1;
declare var q;
