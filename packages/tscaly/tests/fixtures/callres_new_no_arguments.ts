// Slice 108. `new C` without parentheses — hasCorrectArity's own NewExpression arm,
// and a second row with no input.
//
// ★★★ THE ARM IS UNREACHABLE BECAUSE resolveCall IS, ON THE `new` SIDE. A `new` with
// construct signatures stops at `is-constructor-accessible` and one with only call
// signatures at `resolve-call-of-new-expression`, so nothing on that side reaches the
// arity check at all — which is why the arm is written from the reference and priced
// by a control rather than by the corpus.
//
// ★★ THE SECOND LINE IS THE PATH THAT DOES ANSWER: a target with neither construct
// nor call signatures falls out of resolveNewExpression's bottom into invocationError,
// and `new notNew` without parentheses reports TS2351 exactly as `new notNew()` does.
class C { constructor(a: number) {} }
new C;
declare const notNew: { a: number };
new notNew;
