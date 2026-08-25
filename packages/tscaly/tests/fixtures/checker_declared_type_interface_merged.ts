// The 67-unit shape: one interface declared twice. checkTypeParameterListsIdentical
// runs BEFORE the declared type and its `len(declarations) == 1` guard no longer
// fires, so the unit stops one call earlier than a singly-declared interface does.
interface M {
    a: string;
}
interface M {
    b: number;
}
