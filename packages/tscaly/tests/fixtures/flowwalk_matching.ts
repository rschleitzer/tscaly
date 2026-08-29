// isMatchingReference's TARGET arms: an assignment expression, a comma
// expression, a parenthesized target and a non-null target. Each is a shape the
// binder gives a flow assignment node whose `node` is not the reference itself.
function matching(p: number | undefined, q: number) {
    let n: number = q;
    (n) = 1;
    n = 2, n = 3;
    let a = n;
    let m: number = q;
    m += 1;
    let b = m;
    return a + b;
}
