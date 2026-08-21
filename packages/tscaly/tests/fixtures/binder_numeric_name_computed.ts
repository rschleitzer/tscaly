// slice 44 — the numeric name reached through a COMPUTED name, and the signed one
// built out of two nodes.
//
// A computed name whose expression is a literal is treated as that literal, so
// `[0x10]` is the member `16` and merges with `[16]`. A SIGNED one keeps its sign,
// which getDeclarationName builds by prepending the operator's own text to the
// literal's — so `[-1.50]` is `-1.5`: the sign comes from the parser and the rest
// from jsnum, and only the second half moved in this slice.
//
// ★★ `[-0]` is the row where the sign does NOT come from jsnum, and it is worth
// stating because it looks as though it should. A numeric literal is never
// negative — the minus is a separate node — so the literal's own value is `0`, and
// the member is named `-0` because getDeclarationName prepends the operator's
// TEXT. ToString's own negative-zero clause, the reason its safe-integer fast path
// exists at all, is therefore UNREACHABLE from the four yardsticks: slice 44's c16
// is the control that says so and tests/numcheck.sh is what gates it instead.
//
// ★ `[1e21]` is the exponential form through the computed route, which is the same
// arm and a different formatter branch.
class K {
    [0x10] = 1;
    [16] = 2;
    [-1.50] = 3;
    [-0] = 4;
    [1e21] = 5;
}
