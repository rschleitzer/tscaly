// The minimum argument count: an optional parameter, an initializer and a rest
// parameter each stop it from advancing, so `f` answers one and `g` answers zero.
function f(a: number, b?: number, ...rest: number[]): void {
    return;
}
function g(a = 1): void {
    return;
}
