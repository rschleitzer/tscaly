// Slice 91. isReadonlySymbol reached from checkIdentifier — the two codes that
// fork on SymbolFlagsVariable, TS2588 for a constant and TS2540 for a read-only
// property.
//
// ★★ ONLY THE CONSTANT HALF IS REACHABLE FROM HERE and that is a property of the
// caller: checkIdentifier asks about a NAME, and a read-only property is reached
// through a member access, whose chapter is not ported. The second line is the
// negative control for the fork rather than a second report — a `let` is a
// Variable that is not readonly, so it passes the block and falls through to the
// flow graph.
function outer() {
  const a = 1;
  a = 2;
  let b = 1;
  b = 2;
}
