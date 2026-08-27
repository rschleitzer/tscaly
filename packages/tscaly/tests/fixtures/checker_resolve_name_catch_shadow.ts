// SLICE 79: the CATCH VARIABLE the walk can now reach, and the test that stops it.
//
// ★★ Slice 76 measured that all five corpus units reaching this function's symbol
// test were catch clauses; with the resolver in place a catch variable is also
// something the WALK can find, and it is the one block-scoped declaration that is
// not in a VariableDeclarationList — `getDeclarationNodeFlagsFromSymbol` is what
// keeps it out. Its symbol is SymbolFlagsBlockScopedVariable, so the flags test in
// front of it passes; its NODE carries neither Let nor Const, so this one does not.
//
// ★ That is also why the reference may dereference `varDeclList` below without a
// guard, and why a port that dropped the test would report TS2481 here — where both
// sides are silent.
try { } catch (e) { var e; }
