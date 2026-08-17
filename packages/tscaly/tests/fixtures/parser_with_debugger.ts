// `with` puts InWithStatement on its controlled statement, and the flag is
// visible in the dump rather than only in what parses: every node under it
// carries 1 << 24. `debugger` carries no field and no child, so it is a Token
// whose KIND is the whole node — the JSDoc in front of it is what proves the
// node is really there and really finished.
/** d */ debugger;
with (x) y;
with (p) { q(); }
