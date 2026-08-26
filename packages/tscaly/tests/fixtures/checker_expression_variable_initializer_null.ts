// The variable-like declaration's TAIL, which slice 70 transcribes with its
// reports inline: an initializer this port can type reaches
// checkTypeAssignableToAndOptionallyElaborate — the assignability relation — and
// that is the row. The second declaration has no initializer at all and stops at
// checkVarDeclaredNamesNotShadowed instead, which is the other half of the same
// transcription.
//
// ★ Both of them run the trailing block on the way out (checkExportsOnMerged
// Declarations and checkCollisionsForDeclarationName, ported in slices 31 and 59),
// because record_unported does not abort and the reference has no early exit
// here.
var a = null;
var b: number;
