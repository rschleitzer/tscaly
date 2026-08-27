// Slice 73. An INSTANCE member named `prototype` is legal — the negative that
// makes the `isStatic` conjunct of the TS2699 test load-bearing.
//
// ★ It is the third of the prototype report's three conditions: the modifier, a
// non-ambient context (checker_class_static_prototype_ambient.d.ts) and a symbol.
export {};
class C {
    prototype: number = 1;
}
