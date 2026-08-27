// SLICE 80: TS2374 from a TYPE LITERAL, which is the third container kind the
// duplicate-index-signature check has and the one that had never reached it.
//
// checkTypeForDuplicateIndexSignatures takes the NODE, not the type — the note at
// check_type_literal used to claim otherwise, and that claim is what kept these
// two lines behind the stop for three slices. The type literal has no once-guard
// where the class and the interface do: one node, one symbol, nothing to merge.
declare const twoStringIndexes: { [k: string]: any; [j: string]: any };
