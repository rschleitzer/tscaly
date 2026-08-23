// Slice 57. checkGrammarInterfaceDeclaration, both of its reports — TS1172 for a
// second `extends` clause and TS1176 for an `implements` clause on an interface.
//
// ★★★ THE TWO ARE NOT SYMMETRIC AND THE SECOND LINE SHOWS IT. `extends` is
// refused only the SECOND time, so the report needs two clauses; `implements` is
// refused the first time, because an interface has no implements list at all.
// A port that folded the two arms into one seen-flag would answer nothing on
// line 2.
//
// ★★ THE `implements` ARM RETURNS AND THE LOOP THEREFORE STOPS, so the third
// line reports ONCE — the `implements` — and says nothing about the duplicate
// `extends` behind it. That is the reference's `return c.grammarErrorOnFirstToken(...)`
// and it is what makes the arm order visible: an implementation that reported
// both would be a strict superset of the reference's list and diagcheck's
// subsequence test would fail on it.
//
// ★ The last two lines are the negative half: one `extends` with one base, and
// one `extends` with SEVERAL — legal for an interface and illegal for a class,
// which is the whole difference between this head and the class one.
interface A {}
interface B {}
interface C extends A extends B {}
interface D implements A {}
interface E implements A extends B extends A {}
interface F extends A {}
interface G extends A, B {}
