// Slice 91. onSuccessfullyResolvedSymbol's first block, and the row it stands at.
//
// ★★★ THE STOP HERE DOES NOT ABORT THE CALLER, and this fixture is what proves
// it: `a` is a block-scoped const, so checkResolvedBlockScopedVariable is entered
// and records `is-block-scoped-name-declared-before-use` — and the ASSIGNMENT on
// the next line still reports TS2588. A version of this callback that returned
// after its stop would leave this file silent, which is the shape the header
// warns about.
function outer() {
  const a = 1;
  a = 2;
}
