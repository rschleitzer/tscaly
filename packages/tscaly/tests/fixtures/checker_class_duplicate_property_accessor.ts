// Slice 73. The property/accessor combination — a field and a getter of the same
// name are TS2300 on both.
//
// ★★ THE KIND IS WHAT DECIDES, NOT THE ORDER, and this file is the field-first
// half of that claim (checker_class_duplicate_accessor_property.ts is the other).
// The field records kind 1; the getter arrives with kind 2 against state 1, which
// is the reference's `state == 1` case and reports whatever the second kind is.
export {};
class C {
    a: number = 1;
    get a(): number { return 1; }
}
