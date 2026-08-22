// Slice 52. The AMBIENT guard on the trailing-comma check, and it is a guard on
// the PARAMETER rather than on the file.
//
// ★★★ `parameter.Flags & ast.NodeFlagsAmbient == 0` — the ambient flag is
// propagated down from the `declare`, so every parameter of the first line carries
// it and the trailing comma is legal there, while the second line's does not and
// reports TS1013. A file-level test would answer the same for a .d.ts and the
// WRONG thing for exactly this unit, which is why the pair is in one .ts file
// rather than split across a .ts and a .d.ts.
declare function f(...a: any[],): void;
function g(...b: any[],) {}
