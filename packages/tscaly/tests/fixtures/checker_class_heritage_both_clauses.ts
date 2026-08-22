// Slice 51. The result of checkGrammarHeritageClause is DISCARDED — upstream
// writes it as a statement of its own, after the extends/implements bookkeeping —
// so a report inside one clause does not stop the walk over the rest.
//
// ★★ ONE CLASS, TWO DIAGNOSTICS. A port that read the call as part of the `||`
// chain would answer the first and stop, and nothing else in this corpus could
// tell the two readings apart: every other shape reports on a class of its own.
class A<T> {}
class B<T> {}
class C extends A<> implements B<> {}
