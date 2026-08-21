// slice 40 — every function-like kind that can parent a destructured parameter,
// because the name is read off `node.Parent.Parameters()` and that accessor is
// answered per KIND.
//
// ★★★ The two TYPE kinds are why ast.scaly's parameters_of was widened in this
// slice: it used to cover the kinds getFunctionLikeHost can answer, and a
// FunctionType is not one of them, so `([a]: T) => void` reported a port gap the
// moment the arm existed. A signature in a type position binds its parameters
// exactly like one in a value position.
type FT = ([a]: number[]) => void;
type CT = new ({ b }: { b: number }) => object;

interface I {
    m({ c }: { c: number }): void;
    ({ d }: { d: number }): void;
    new ([e]: number[]): object;
}

class A {
    constructor({ f }: { f: number }) {}
    m([g]: number[]) {}
    set s({ h }: { h: number }) {}
    static st({ i }: { i: number }) {}
}

const fe = function ({ j }: { j: number }) { return j; };
const ar = ({ k }: { k: number }) => k;
declare function df([l]: number[]): void;
