// SLICE 76: a `let` is finished before anything is asked, and that is why the row
// this slice emptied was the largest by UNIT in the whole stop histogram — 405
// events over 245 units in front of a function whose reference returns at its own
// first line. The port used to record a stop here, i.e. name a wall in front of
// something that does nothing.
//
// ★★★ WHAT IT DOES NOT PIN, measured by the battery rather than assumed: it does
// not separate the FLAGS guard from the SYMBOL test. Drop
// `combinedNodeFlags&BlockScoped` (control g02) and this file does not move — the
// symbol of a `let` is SymbolFlagsBlockScopedVariable, so the third test finishes
// it just as well. The two are subsumed for every let/const/using, and the file
// that tells them apart is checker_var_shadow_catch_inert.ts.
//
// * The unit's tag is therefore `type-of-node`, raised by the DUMP walk after the
// CHECK has run to the end. That is the shape slice 76's instrument half exists
// for: before it, a unit like this logged no stop at all and the loop filed it
// under "the checker never ran".
let y: string;
