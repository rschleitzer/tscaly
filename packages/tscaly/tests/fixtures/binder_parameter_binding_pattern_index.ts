// slice 40 — the INDEX is the whole content of the name. `slices.Index(
// node.Parent.Parameters(), node)` is asked of the parent's list, so the name
// counts EVERY parameter and not just the destructured ones: the pattern here is
// `__1`, not `__0`.
//
// ★★ Two patterns in one signature is the row that cannot be got wrong quietly.
// Anything that counted patterns instead of parameters, or reused a per-signature
// counter, would name both of them the same — two symbols with one name, which
// the dump shows and which no table would ever complain about, since an anonymous
// declaration is added to no table at all.
function f(a: number, { b }: { b: number }, c: number, [d]: number[]) {
    return a + b + c + d;
}

// ★ And the counting starts over per SIGNATURE, because the list is the parent's:
// this pattern is `__0` again even though a `__0` was minted three lines up.
function g({ e }: { e: number }) {
    return e;
}
