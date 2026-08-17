// `throw [no LineTerminator here] Expression` — and the reference does NOT
// report here. It synthesizes a zero-width MISSING identifier, leaves the
// complaint to the grammar walker, and lets ASI end the statement, so this is
// TWO statements and the first has a child of width 0. Its own fixture because
// it must be the first shape in the file.
throw
x;
