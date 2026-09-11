// `new` on a type with call signatures and no construct signature: the reference
// resolves the CALL signature and, with noImplicitAny off, reports TS2350 when the
// return type is not void — and TS2349 nothing at all when it is.
function f(): number { return 1; }
var x = new f();

function v(): void { }
var y = new v();

function tv(this: void): void { }
var z = new tv();
