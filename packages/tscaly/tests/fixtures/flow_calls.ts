// The two calls that join the flow graph: a top-level call with a DOTTED callee
// (potentially an assertion) and a `super()` call. An IIFE is part of the
// containing control flow and gets no Start node of its own; a generator or an
// async function expression is not.
declare namespace ns { function assert(v: unknown): asserts v; }
declare function plain(v: unknown): void;

class Base { constructor(public n: number) {} }
class Derived extends Base {
    constructor() {
        super(1);
        this.n = 2;
    }
}

function calls(v: unknown) {
    ns.assert(v);
    plain(v);
    (function () { return 1; })();
    (() => 2)();
    (async function () { return 3; })();
    (function* () { yield 4; })();
    (plain(v), ns.assert(v));
}
