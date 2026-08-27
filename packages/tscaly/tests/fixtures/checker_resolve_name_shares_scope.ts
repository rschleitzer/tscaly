// SLICE 79: the NEGATIVE half of the container walk — a FUNCTION BODY block, where
// the two names DO share a scope and the reference says nothing.
//
// The `let` sits in the block that IS the function's body, so `IsBlock(container) &&
// IsFunctionLike(container.Parent)` holds: after hoisting, the `var` lands in the
// same scope the `let` is in, which is the binder's business and not this check's.
// ★A port that dropped the namesShareScope test would report TS2481 here — the
// direction diagcheck catches, which is what this fixture is for.
function shares() {
    let y;
    {
        var y;
    }
}
