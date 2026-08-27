// Slice 73. TS2699 — a static member named `prototype` collides with the built-in
// property of the constructor function.
//
// ★★ IT IS THE ONE REPORT OF THIS FUNCTION THAT IS NOT ABOUT A DUPLICATE, and it
// needs no map: one static `prototype` is enough, and the guard is the modifier
// plus a non-ambient context. checker_class_static_prototype_ambient.d.ts is the
// negative for the second half.
//
// ★ The message takes the symbol's name twice and the class's name once; a
// message ARGUMENT is not in the C lines this suite compares, so what is gated
// here is the code and the span.
export {};
class C {
    static prototype: number = 1;
}
