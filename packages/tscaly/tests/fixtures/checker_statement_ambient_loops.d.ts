// Slice 64. The last five callers of checkGrammarStatementInAmbientContext, and the
// once-bit landing where the reference puts it.
//
// ★★★ THE BLOCK'S BIT BELONGS TO WHICHEVER STATEMENT COMES FIRST, and until this
// slice a namespace body opening with a `for` was UNKNOWABLE: the arm was not ported,
// so spend_ambient_report_of_container marked the block and the port said nothing
// rather than report the TS1036 two statements late. Here the `for` is first, its arm
// exists, and the diagnostic lands on it.
//
// ★★ THE SECOND BODY IS THE SAME FACT FOR THE `return`, whose arm RETURNS on a true
// answer from the ambient check — so the TS1108 that a top-level `return` would get
// is correctly absent here, and the only diagnostic is the block's own TS1036. A port
// that ran the container walk before the ambient check would invent one.
//
// ★ The third body opens with a `switch`, whose arm IGNORES the ambient check's
// answer and walks its clauses regardless — the reference's own shape, and the reason
// the `break` inside the clause still reports.
declare module A {
    for (;;) { }
    if (1) { }
}
declare module B {
    return;
}
declare module C {
    switch (1) { case 1: break nosuch; }
}
