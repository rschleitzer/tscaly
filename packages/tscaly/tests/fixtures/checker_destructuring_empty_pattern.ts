// Slice 117 — the binding pattern that binds NOTHING, which is the only shape
// where `needCheckWidenedType` is true.
//
// ★★★ IT DECIDES WHICH CHECK THE INITIALIZER GETS. With a pattern that binds
// something the initializer is tested for ASSIGNABILITY to the widened type;
// with one that binds nothing there is nothing to assign to, so under
// strictNullChecks it is only tested for being null or void — which is why
// `const {} = maybe` reports TS2532 and `const {x} = maybe` does not report here.
// ★ `void` is the arm checkNonNullNonVoidType adds on top of checkNonNullType, and
// the empty pattern is the only caller in this slice that can reach it.
declare const obj: { x: number };
declare const maybe: { x: number } | undefined;
const {} = obj;
const {} = maybe;
declare const v: void;
const {} = v;
