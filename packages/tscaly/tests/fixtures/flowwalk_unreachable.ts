// The DEFAULT arm of getTypeAtFlowNode -- "unreachable code errors are reported
// in the binding phase; here we simply return the non-auto declared type to
// reduce follow-on errors" -- and the unreachableNeverType the assignment arm
// answers for a target behind a `return`.
function dead(p: number) {
    let n: number = p;
    return n;
    n = 1;
    let a = n;
}
function afterThrow(p: number): number {
    let n: number = p;
    throw new Error("x");
    let b = n;
}
