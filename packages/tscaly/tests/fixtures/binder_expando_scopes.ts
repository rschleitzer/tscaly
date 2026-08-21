// slice 38 — the two container registers, which is what ExpandoAssignmentInfo
// carries and what makes this a pass over a LIST rather than a loop over nodes.
//
// `g` is declared three times in three scopes, and each assignment must resolve
// in the scope it is WRITTEN in. By the time the pass runs the walk is over and
// both registers point at whatever came last, so an entry that did not carry its
// own registers would attach every property to one `g`.
//
// The inner block additionally gates the ORDER of the two lookups: the reference
// asks blockScopeContainer FIRST and container only if that answered nothing.
// Here they answer DIFFERENTLY — the block's `g` is a const arrow, the function's
// is a declaration — so `g.c` says which register was asked first.
function g() {}
g.a = 1;

function outer() {
    function g() {}
    g.b = 2;
    {
        const g = () => {};
        g.c = 3;
    }
}
