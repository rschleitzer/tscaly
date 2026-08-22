// Slice 55. checkParameter's `this` quartet, of which the corpus can reach ONE:
// `slices.Index(fn.Parameters(), node) != 0` on a parameter named `this`.
//
// ★★ THE OTHER THREE TESTS OF THE SAME BLOCK NEED A HOST THIS WALK DOES NOT
// REACH — a constructor, a construct signature, a constructor type, an arrow, an
// accessor — so they are all in checker_parameter_this_deferred.ts. What is left
// here is the index test, and a function declaration is host enough for it.
//
// ★★ THE FIRST LINE IS THE NEGATIVE HALF AND IT IS THE ONE THAT MATTERS: `this`
// in position 0 is LEGAL and must be silent. A port that reported on every `this`
// parameter would pass on the second line alone, and the whole content of the
// test is the index.
//
// ★ `new` is the block's other name and there is no line for it, because the
// PARSER refuses it: `function f(b: number, new: any) {}` yields a zero-width
// missing identifier where the name should be, so paramName is empty and the
// block is never entered. The name survives in the port because it is the
// reference's condition, not because a TypeScript parameter list can spell it.
function ok(this: any, b: number) {}
function bad(b: number, this: any) {}
