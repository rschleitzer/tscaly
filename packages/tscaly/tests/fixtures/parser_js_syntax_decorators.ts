// Slice 24 — checkJSDecoratorSyntax, which is the only part of the JS-syntax
// pass that is about PLACEMENT rather than about a construct being TypeScript.
// It runs on every node, between the two switches, and asks two questions in
// order:
//
//   CanHaveIllegalDecorators   a decorator here is wrong wherever it sits
//                              -> 1206 at the first decorator
//   CanHaveDecorators          only the ORDER around `export`/`default` is
//                              -> 1206 for one between `export` and `default`
//                              -> 8038 for one before `export` with another
//                                 after it
//
// ★ The 8038 case also carries RELATED INFO (`Decorator used before export
// here`, 1486), which the reference attaches to the diagnostic rather than
// appending to the list — so it never reaches this dump, exactly as
// parseExpectedMatchingBrackets' related info never reaches the D section. The
// port therefore appends one entry, and that is not a shortcut: a second entry
// would be a divergence.
//
// The last two class declarations are the ordering pair; the four before them
// are illegal hosts. Read the whole file as the ORDER of the two questions —
// `@dec export default class` is legal placement on a legal host and must be
// silent, and it is the line that separates a working order from an inverted one.
// @Filename: decorators.js
@dec
function f() {}

@dec
var a = 1;

@dec
interface I {}

@dec export default class A {}

@dec export class B {}

export @dec default class C {}

@first export @second class D {}
