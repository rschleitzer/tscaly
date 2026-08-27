// SLICE 76: the SYMBOL test, and it is not a duplicate of the flags guard — the two
// are different spellings of "block-scoped" and this file is the proof that the
// function needs both.
//
// A catch clause's variable is a VariableDeclaration whose NODE carries no Let and
// no Const, so `getCombinedNodeFlagsCached&BlockScoped` is zero and the first guard
// lets it through; its SYMBOL is SymbolFlagsBlockScopedVariable (2), so
// `symbol.Flags&FunctionScopedVariable` is zero and the third test finishes it.
//
// * Measured rather than reasoned: the five corpus units that reach the symbol test
// at stage 1 are all catch clauses, and all five report flags exactly 2.
try { } catch (e) { }
