namespace ns { export interface I { n: number } }
declare const ns2: { x: number };
class B { p = 1 }
class D extends B {
    q = 2;
    m(): this {
        const t: typeof ns2.x = super.p;
        const { a, b: [c] } = { a: 1, b: [2] };
        function g() { return new.target; }
        return this;
    }
}
let y: ns.I;
