// checkInheritedPropertiesAreIdentical past its `len(baseTypes) < 2` guard: an
// interface with TWO bases that declare the same property name.
//
// `Bad` is the report — TS2320, and the code is the CHAIN'S head rather than the
// TS2319 the inner message carries. `Good` is the negative control: the same two
// bases with an identical member, which must stay silent, and `Own` is the second
// one — a member declared on the extending interface itself is `seen` with the
// interface as its containing type, which the arm skips instead of comparing.
interface A { x: number }
interface B { x: string }
interface C { x: number }
interface Bad extends A, B {}
interface Good extends A, C {}
interface Own extends A, B { x: number }
