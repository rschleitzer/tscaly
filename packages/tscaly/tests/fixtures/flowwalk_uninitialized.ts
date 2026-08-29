// An uninitialized `let` whose declared type does not admit undefined:
// assumeInitialized is false, so the initial type is getOptionalType(t, false)
// -- a union with undefined, and the wall this chapter stands at.
function uninit(q: boolean): number {
    let n: number;
    if (q) {
        n = 1;
    } else {
        n = 2;
    }
    return n;
}
