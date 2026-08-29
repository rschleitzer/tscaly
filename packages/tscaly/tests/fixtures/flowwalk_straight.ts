// The path that ANSWERS: a variable with a declared type, reached over
// straight-line flow and over an assignment to itself. An assignment narrows
// only where the declared type is a union, so for these the whole arm is the
// reachability test and the identity of the target.
function straight(p: string) {
    let s: string = p;
    let t = s;
    s = p;
    let u = s;
    const c: number = 1;
    let v = c;
    return t;
}
