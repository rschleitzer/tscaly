// SLICE 87, and it is the NEGATIVE control of the fixture above. The computed name
// is on the INSTANCE side, so `isStatic == HasStaticModifier(member)` is false for
// it and the static half resolves without stopping. If getExportsOfSymbol ever
// folds into getMembersOfSymbol with a flag, this is the file that goes red.
const k = "x";
class C {
    [k]: string;
    static a: string;
}
