// Slice 101: The comparisons that must STOP rather than answer: the target is a union
// (`boolean` is one), the source is an object, or both are.
var t: boolean = "x";
var o: string = { a: 1 };
var p: object = { a: 1 };
