// Slice 60. checkTypeParameters' seenDefault report — TS2706, *required type
// parameters may not follow optional type parameters*.
//
// ★★★ THE FLAG IS STICKY OVER THE WHOLE LIST AND THE REPORT IS ON THE PARAMETER
// THAT HAS NO DEFAULT, so the interface below reports on `C` and NOT on `B`: two
// defaults in a row are fine and it is the first parameter after any of them that
// is wrong. A two-parameter fixture cannot show that — with `<T = string, U>`
// alone, "sticky" and "looks at its predecessor" give the same answer.
export {};
function f<T = string, U>(): void {}
interface I<A = string, B = number, C> { a: A, b: B, c: C }
