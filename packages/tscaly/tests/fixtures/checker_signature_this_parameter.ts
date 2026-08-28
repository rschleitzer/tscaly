// The signature's `this` parameter: the FIRST parameter whose SYMBOL is named
// `this`, which is one of the few internal names carrying no 0xFE prefix. A
// `this` parameter is not counted into `parameters`, so the minimum argument
// count of `g` is one and not two.
interface Ctx {
    n: number;
}
function g(this: Ctx, a: number): number {
    return a;
}
