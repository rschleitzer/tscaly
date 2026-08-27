// SLICE 82: the OTHER half of the reference's first early return — `t.flags &
// (Any | Undefined)`, which is a plain flags test beside maybeTypeOfKind's void
// question. Two fixtures rather than one because the two halves are two different
// tests over one `if`, and a control that breaks either must have a file that can
// see it.
function anyReturn(): any {
}
