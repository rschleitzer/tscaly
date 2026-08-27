// Slice 73. checkObjectTypeForDuplicateDeclarations' property/property arm —
// TS2300, *duplicate identifier*.
//
// ★★★ THREE DECLARATIONS, BECAUSE THAT IS WHAT SEPARATES THE REPORTER FROM A
// COUNTER. The state machine trips on the SECOND `a` and calls
// reportDuplicateMemberErrors once; that call walks the WHOLE member list, so the
// THIRD `a` — declared after the trip — collects a diagnostic too, and the third
// visit itself reports nothing because the state is already 3. Three diagnostics
// from one report call, in member order. At two declarations a per-member counter
// and the reference's whole-list walk answer the same thing.
export {};
class C {
    a: number = 1;
    a: string = "x";
    a: boolean = true;
}
