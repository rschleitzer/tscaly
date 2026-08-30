// Slice 101: elaborateError, reached the only way this slice can reach it: an OBJECT source
// against a PRIMITIVE target, which isRelatedToEx answers in a branch of its own
// BEFORE normalization and therefore does not stop on. The first line is the
// elaborator's own first test (a primitive target is not elaborated, so the
// relation's plain report stands); the second and third are its two recursion
// arms, the parenthesized expression and the comma operator.
var o: string = { a: 1 };
var p: string = ({ a: 1 });
var q: string = (0, { a: 1 });
var r: number = {};
