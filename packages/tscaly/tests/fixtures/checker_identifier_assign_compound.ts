// Slice 91. The three assignment SHAPES getAssignmentTargetKind tells apart, and
// the one place the distinction changes an answer.
//
// ★★★ THE KIND IS NOT ONLY A YES/NO. `a += 1` is COMPOUND and `a = 1` is
// DEFINITE, and checkIdentifier reads the difference twice: the report block fires
// for either, but the early `return t` fires only for Definite — a compound
// assignment falls through to the flow graph, because its READ still has to be
// narrowed.
//
// ★★★ THE TWO INCREMENTS ARE A DOCUMENTED LOSS AND THEY ARE HERE FOR THAT. Both
// are Compound targets and the reference reports TS2588 on each; this port reports
// neither, because `check-postfix-unary-expression` and
// `check-prefix-unary-expression` are rows and the identifier under them is never
// checked at all. The chapter that decides the report is ported and the chapter
// that WALKS to it is not — which is exactly the asymmetry §3.5ce names, and the
// stop log is where it is visible.
//
// ★ `b = b << 1` is the compound-LIKE shape isInCompoundLikeAssignment asks about:
// a definite assignment whose right operand is a shift-or-higher binary
// expression. It is what sends the DEFINITE branch to getBaseTypeOfLiteralType
// instead of answering `t`.
function outer() {
  const a = 1;
  a += 1;
  a++;
  --a;
  let b = 1;
  b = b << 1;
}
