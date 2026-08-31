// SLICE 112: three shapes the ordinary fixtures do not reach — a function EXPRESSION
// whose end is unreachable (mayReturnNever), an INITIALIZED parameter that is not
// optional because a required one follows it, and an ambient accessor pair with no
// annotation on either side. The FOURTH, an arrow contextually typed by a return type
// that includes undefined, has no home here: every route to a contextual signature in
// this corpus goes through an assignability check that stops.
const thrower = function () { throw 1; };
class F { method(a = 0, b) { } }
declare class G { get s(); set s(v); }
