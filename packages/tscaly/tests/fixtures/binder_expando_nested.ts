// slice 38 — lookupEntity's RECURSION, and the arm of getInitializerSymbol whose
// value declaration is a BINARY EXPRESSION.
//
// Three hops in three lines. `Foo` is a JavaScript variable initialized with an
// empty object literal, so its expando host is the OBJECT LITERAL's symbol.
// `Foo.bar = function () {}` declares `bar` there, with the assignment itself as
// its value declaration. `Foo.bar.baz = 1` then has to resolve `Foo.bar`: not an
// identifier, so lookupEntity recurses into `Foo`, takes its initializer symbol,
// looks `bar` up in that symbol's EXPORTS, and asks getInitializerSymbol of the
// result — whose value declaration is a binary expression in a JavaScript file
// with a function expression on the right, so the host is the FUNCTION
// EXPRESSION's symbol.
//
// `Foo.nope.deep = 2` is the same shape one step short of resolving: `nope` is an
// expando whose right operand is a number, which is not an expando initializer,
// so the third hop finds no host and nothing is declared.
// @Filename: nested.js
var Foo = {};
Foo.bar = function () {};
Foo.bar.baz = 1;
Foo.nope = 3;
Foo.nope.deep = 2;
