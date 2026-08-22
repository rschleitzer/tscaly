// Slice 49. TS1040 — `{0} modifier cannot be used in an ambient context` — from
// the `declare` arm, which is the one arm that reads the flags accumulated by
// EARLIER modifiers of the same list rather than the node's own shape.
//
// ★★ THE ARM READS TWO SOURCES OF `ambient` AND THE UNIT NEEDS BOTH STATEMENTS
// TO SEE THEM APART. `flags&Ambient` is a `declare` earlier in the SAME modifier
// list; `node.Parent.Flags&Ambient` is the whole FILE being a declaration file.
// The first line reports through the list, the second through the file — same
// code, same shape, two mechanisms — and with only the first line the parent test
// is redundant and its control is ungated.
declare async var a: number;
async var b: number;
