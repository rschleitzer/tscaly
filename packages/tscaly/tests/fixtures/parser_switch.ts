// The case block is a node of its own, its clause list is UNDELIMITED, and a
// clause's statement list ends at the next `case`/`default` as well as at the
// block's `}` — which is why switch clauses need a parsing context of their
// own rather than reusing the block-statement one.
switch (x) { case 1: a(); break; default: b(); }
switch (y) { }
switch (z) { case 1: case 2: c(); break; }
switch (w) { default: }
