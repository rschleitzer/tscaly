// Slice 115's CONSTRUCT half of getReturnTypeOfSingleNonGenericSignature. It is
// UNPORTED by construction and kept as the pin for the arm's SHAPE: `new C()`
// reaches is_constructor_accessible, a wall of the call-resolution chapter, so no
// yardstick can see the arm — the stop TAG is what says the arm ran.
declare class C { y: number; }
let b = new C();
