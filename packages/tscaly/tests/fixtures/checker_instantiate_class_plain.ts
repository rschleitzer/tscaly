// SLICE 86. The simplest type reference there is: a NON-GENERIC class, whose
// allTypeParameters is the thisType alone and whose padded arguments are the type
// itself. The mapper is `{thisType -> C}`, MapsThisOnly is true, and both members
// are thisless — so instantiateSymbol answers each of them unchanged and no
// transient symbol is minted at all. The index signature is what makes the result
// visible: `check-index-constraint` in the stop log means an IndexInfo was built.
class C {
    [k: string]: string;
    a: string;
}
