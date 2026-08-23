// Slice 61. checkTupleType's ordering loop — its three grammar reports, and the
// element shapes that produce each.
//
// ★★★ THE REST/VARIADIC DISTINCTION IS SYNTACTIC HERE AND THAT IS WHAT MAKES THE
// LOOP PORTABLE. `...string[]` is a REST element because getArrayElementTypeNode
// recognises the array SYNTAX; `...T` where T is a bare reference is VARIADIC and
// its flags depend on a type this port cannot compute — so every element below
// spells its rest with an array type, and the variadic case is
// checker_tuple_variadic_stop.ts's subject instead.
//
// ★ Each report BREAKS the loop, so one tuple can carry at most one of them and
// the fixture needs three.
export {};
declare const requiredAfterOptional: [string?, number];
declare const restAfterRest: [...string[], ...number[]];
declare const optionalAfterRest: [...string[], number?];
