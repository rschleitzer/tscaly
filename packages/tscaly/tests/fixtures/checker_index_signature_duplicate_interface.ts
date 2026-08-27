// SLICE 77: TS2374, and the interface half of the one call in
// checkClassOrInterfaceForDuplicateIndexSignatures' sequence that needs neither
// the members dimension nor the flow graph.
//
// Two string index signatures on one interface: the reference groups the index
// symbol's declarations by the TYPE of their single parameter and reports every
// declaration of a group with more than one member — so this file expects TWO
// diagnostics, not one.
interface I { [k: string]: any; [j: string]: any; }
