// Slice 51. The four reports of checkGrammarClassDeclarationHeritageClauses' own
// bookkeeping, in one unit so that the SORT is visible: they are discovered in
// class order here, which is also position order, and the fixture below with two
// reports on one class is where discovery and sorted order can differ.
//
// ★ Each of the four RETURNS, so a class that reports one of them never reaches
// checkGrammarHeritageClause — which is why `F` reports TS1174 and not the
// trailing-comma or empty-list check of its own second type.
class A {}
class B {}
interface I {}
interface J {}
class C extends A extends B {}
class D implements I extends A {}
class E implements I implements J {}
class F extends A, B {}
