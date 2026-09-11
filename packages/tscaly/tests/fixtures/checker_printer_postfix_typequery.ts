// Slice 183: a TypeQueryNode is TypePrecedenceTypeOperator, so an array of one
// is `(typeof C)[]` and not `typeof C[]` — a different type. The reference's own
// precedence table names this spelling in its comment.
class C { private p = 1 }
declare const a: (typeof C)[];
declare function mk<T>(x: T): (typeof C)[];
const b = mk(1);

// A type reference records NonArray at every exit: without it the last type
// ARGUMENT's precedence leaked out and parenthesised the reference itself.
interface TC<T> { v: T }
declare function mt<T>(x: T): TC<T>[];
const c = mt<string | number>("a");
interface TH<T> { w: T }
declare function mh<A, B>(x: A, y: B): TH<A & B> & { z: number };
const d = mh({ a: 1 }, { b: 2 });
