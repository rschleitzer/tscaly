// SLICE 72's ONE REACHABLE STOP inside getWidenedLiteralType, and no corpus unit
// at stage 1 reaches it — which is why this file exists (§3.5ap: a fixture that
// gates nothing is invisible until a control aims at one).
//
// * `let b = true` needs `booleanType` to widen the fresh true type to, and that
// type is getUnionType([regularFalse, regularTrue]) — the same missing union
// slice 71 left named at the LiteralTypeData field and at type_to_string's
// Boolean arm. So this slice makes a THIRD reader for it and all three report.
//
// * THE `const` HALF IS ITS OWN FILE, and the split is the instrument's lesson
// rather than a preference: the unported TAG is FIRST-WINS, so a `const cb = true`
// under this file's first line could never be seen — the control aimed at the
// short-circuit that keeps it out of this arm would come back green whatever it
// broke. See checker_initializer_boolean_const.ts.
//
// * BOTH KEYWORDS ARE HERE because the reference's literal case names them
// together and they share one payload record; they are not two gates.
let b = true;
let f2 = false;
