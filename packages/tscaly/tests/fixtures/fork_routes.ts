// Slice 103: The three routes out of the fork that are NOT the union relation.
// Each is a stop and each stands where the reference calls the piece this slice
// does not port — so the FORKPIN's route column is the whole content of this
// file, and its verdict column is 2 on every row.
//
// ★★ THE FIRST TWO ARE ORDERED AND THE ORDER IS THE REFERENCE'S: the excess-
// property check runs BEFORE the common-property one, so a source that is a
// FRESH OBJECT LITERAL can never reach route 1. The function expression on the
// first line is what makes route 1 reachable at all — it is an Object type that
// is not an object literal.
var commonRoute: { a?: number } = function () { return 1 };
var excessRoute: { a: number } = { a: 1, b: 2 };
var excessWeak: { a?: number } = { c: 3 };

// ★ Route 3 — the recursion. Its ONE condition is skipCaching's threshold: a
// union target of FOUR OR MORE constituents against a non-structured source is
// the one shape in this port that does not take the union relation directly.
var recurseWide: number | string | boolean | object | symbol = 1;
