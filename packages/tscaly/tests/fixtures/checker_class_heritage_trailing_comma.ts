// Slice 51. checkGrammarForDisallowedTrailingComma, on both heritage clauses.
//
// ★★ `HasTrailingComma()` IS DERIVED UPSTREAM TOO — `last.End() < list.End()` —
// so the side table is the only thing it needs that the elements do not carry.
// The report is one character wide, at `list.End()-len(",")`.
//
// ★ The extends clause here has ONE element, so it is this check that reports and
// not `Classes can only extend a single class`: the count test is `> 1` and a
// trailing comma adds no element.
class A {}
interface I {}
class C extends A, {}
class D implements I, {}
