// The three shapes the quick path REFUSES: an OVERLOADED callee (two call
// signatures), a GENERIC one, and a call CHAIN. Each answers nil rather than
// stopping, and the unit's tag then names the ordinary dispatch — which is the whole
// evidence that the refusal happened rather than an answer being invented.
declare namespace N {
    interface A { x: number; }
    declare function over(x: string): A;
    declare function over(x: number): A;
    declare function gen<T>(x: T): T;
    declare let maybe: (() => A) | undefined;
    let c = over("s");
    let d = gen(1);
    let e = maybe?.();
}
