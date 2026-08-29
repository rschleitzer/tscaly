// Slice 98: the wall and the two arms with no input, each written so the file
// reaches what it can and names what it cannot.
//
// The INTERSECTION arm is a stop here — it re-anchors every constituent and
// rebuilds the intersection, and getIntersectionType is a chapter of its own. What
// this file measures is that the arm is not even the first wall an intersection
// meets: `A & B` stops at `get-type-from-type-node 194`, the IntersectionType arm
// of getTypeFromTypeNode, one whole chapter in front of it. So no intersection in
// this corpus is ever a TYPE, and the arm below cannot have an input by
// construction rather than by luck.
//
// ★ The needApparentType TAIL (arm 3) has no input either, and for a reason one
// call further out: its only true caller upstream is getApparentTypeOfIntersection
// Type, which is reached from the same intersections that never get here. It is
// written from the reference and defended from the reference.
//
// ★★ The ARITY arm (arm 2) is the reference's IDEMPOTENCE guard and not an error
// path: a reference that has ALREADY been re-anchored carries one type argument
// more than its target has type parameters, so the test fails and the input comes
// back unchanged. Nothing in this corpus asks twice.
export {}

interface A { a: number }
interface B { b: number }

function f(x: A & B): number {
    return x.a
}
