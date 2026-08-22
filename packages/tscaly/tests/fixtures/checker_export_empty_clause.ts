// Slice 50. The one shape of this family whose ARM runs to the end — and the unit
// still cannot be claimed, which is the measurement.
//
// With no module specifier the `||` short-circuits, so
// checkExternalImportOrExportDeclaration is never asked; with an empty clause the
// specifier loop has nothing to visit; the three context bools permit an export at
// the top level of a file; and checkImportAttributes returns at its own first line
// because there is no `with { … }`. So the check reaches the bottom of
// checkExportDeclaration for both statements.
//
// ★★★ AND THE UNIT IS STILL UNPORTED, BECAUSE A FILE WITH AN EXPORT IS A MODULE.
// checkSourceFile's last branch reports check-external-module-exports for any
// external module, so no unit of this family can move the matched count — the same
// shape of argument slice 49 made for why ITS count could not move, arriving from
// the other end: there the arm never finished, here the arm finishes and the FILE
// does not.
//
// ★★ WHAT IT DOES GATE is the permitted-context computation, and diagcheck can see
// it: get `in_ambient_external_module` / the SourceFile test wrong and this unit
// INVENTS a TS1194, which is a diagnostic the reference does not have. A fixture
// whose expected answer is "nothing" is still a gate when the failure mode is a
// line rather than a missing one.
export {};
export type {};
