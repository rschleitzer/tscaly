// Slice 183: mapToTypeNodes' collision pass. Two constituents of one list that
// print the same bare name for DIFFERENT types are re-rendered with
// UseFullyQualifiedType, which is the flag that turns the symbol chain on.
class c { private p = 1 }
module m { export class c { private q = 1 } }
declare function mk<A, B>(x: A, y: B): [A, B];
declare const ca: c;
declare const cb: m.c;
const pair = mk(ca, cb);

namespace Foo { export interface Yep { a: number } }
namespace Bar { export interface Yep { b: number } }
declare function u(): Foo.Yep | Bar.Yep;
const y = u();

// The negative control: one name for one type stays bare, and a generic
// reference whose constituents share a symbol is homogeneous — no qualifier.
namespace Solo { export interface Only { a: number } }
declare function v(): Solo.Only;
const z = v();
interface Gen<T> { g: T }
declare function w(): Gen<string> | Gen<number>;
const q = w();
