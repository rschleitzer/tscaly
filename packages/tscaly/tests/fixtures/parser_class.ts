class A {}
class B { x; }
class C { x = 1; y: number = 2; }
class D { m() {} n(a: string): void {} }
class E { static s = 1; readonly r = 2; private p = 3; }
export class F {}
export default class G {}
declare class H { x: number; }
abstract class I { abstract m(): void; }
class J<T> { v: T; }
class K { *gen() { yield 1; } async am() {} }
class L { #priv = 1; m() { return this.#priv; } }
let M = class {};
let N = class Named {};
class O { ; }
class P { m(); m(a: number); m(a?: number) {} }
