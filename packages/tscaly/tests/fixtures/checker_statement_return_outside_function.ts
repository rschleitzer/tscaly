// Slice 64. checkReturnStatement's second grammar report, TS1108, which is the one
// of its two that this port can reach.
//
// ★★★ IT FIRES ON THE ABSENCE OF A CONTAINER, i.e. on a `return` whose ancestor walk
// finds no function-like node and no class static block — and a top-level `return` is
// exactly that. The report is on the FIRST TOKEN, not on the statement: `return 1;`
// spans four characters here and eight in the source.
//
// ★★ THE THIRD LINE IS THE SAME REPORT ONE CONTAINER DOWN AND IT IS THE WALK THIS
// SLICE ADDED. Before the loop arms existed nothing walked into a `while` body, so a
// `return` inside one was never reached at all — the diagnostic is the loop arm's
// yield and not this function's.
//
// ★ The fourth is the negative: a `return` inside a function body has a container,
// takes neither grammar branch, and stops at `get-signature-from-declaration`. It
// reports nothing, which is what makes the three above a measurement.
return;
return 1;
while (1) { return; }
function f() { return 1; }
