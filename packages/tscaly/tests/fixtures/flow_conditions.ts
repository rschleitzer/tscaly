// The conditional graph: `&&` sends the left's TRUE branch to the right operand
// and `||` sends its FALSE branch there, a `!` swaps the two targets, and a
// literal `true`/`false` on the wrong side of a condition kills the branch.
declare const a: string | undefined;
declare const b: number | null;

function conditions(x: unknown) {
    if (a && b) { a; }
    if (a || b) { b; }
    if (!(a && b)) { a; }
    if (a ?? b) { a; }
    const t = a ? 1 : 2;
    if (true) { t; }
    if (false) { t; }
    while (true) { break; }
    let c = a;
    c &&= "x";
    c ||= "y";
    c ??= "z";
    return typeof x === "string" && x.length;
}
