// slice 38 — the reference's own comment, gated: "we declare expandos only when
// there are no non-expando declarations for that name."
//
// `f` is a function merged with a namespace, so its exports already hold a real
// `a` — a const with no Assignment flag. The expando `f.a = 2` is therefore
// DROPPED rather than merged, and `f.b` beside it shows the test is about the
// NAME and not about the symbol: b has no non-expando declaration, so it lands.
function f() {}
namespace f {
    export const a = 1;
}
f.a = 2;
f.b = 3;
