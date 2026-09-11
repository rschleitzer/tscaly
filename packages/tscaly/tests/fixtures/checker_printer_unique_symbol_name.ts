// Slice 183: a property whose nameType is a unique symbol prints as a COMPUTED
// name — `[sym]` — and an INSTANTIATED member keeps the nameType slot, which
// instantiate_symbol had been dropping.
declare const sym: unique symbol;
interface I { [sym]: number }
declare function f(): I;
const a = f();
declare function g<T>(x: T): { [sym]: T };
const b = g(1);
