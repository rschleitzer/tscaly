// Slice 106. checkTypeParameterDeferred's other two PARENTS — the class-like one
// and the invariant case that owes no comparison at all.
//
// ★★★ THE GUARD NAMES THREE PARENTS AND THE ALIAS IS THE ONLY ONE WITH A REPORT,
// so a class is the input that proves the other two arms are reached rather than
// guarded away. `class C<in T>` takes the marker route and stops there;
// `class D<in out T>` carries BOTH flags, which is invariance — `modifiers == In
// || modifiers == Out` is false for it and the reference's own answer is nothing.
//
// ★★ THE INVARIANT CASE IS THE ONE A WRONG READING GETS WRONG SILENTLY. Read the
// test as `modifiers != 0` (which the arm above it already is) and `in out` takes
// the marker route too, which is a stop this port would record and a comparison
// the reference never makes. It costs no diagnostic in either direction, so only
// the stop log can see it.
//
// ★★★ `K` IS THE VIOLATION, AND IT IS AN INTERFACE PROPERTY RATHER THAN A METHOD
// FOR A REASON THE FIRST DRAFT GOT WRONG. `class E<out T> { m(x: T) {} }` is what
// a reader reaches for and the reference says NOTHING about it: a METHOD's
// parameters are compared bivariantly, so a covariant parameter in one is not a
// violation. A property of function type is compared strictly, which is why the
// alias `Bad` in variance_alias.ts reports and the method does not.
export {};
class C<in T> { m(x: T) { } }
class D<in out T> { m(x: T): T { return x; } }
class E<out T> { m(x: T) { } }
interface J<out U> { u: U }
interface K<out U> { f: (x: U) => void }
