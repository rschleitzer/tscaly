// Slice 73. A static and an instance member may share a name.
//
// ★★★ IT IS A NEGATIVE ON THE GUARD AND NOT ON THE TWO MAPS, which is the
// opposite of what it looks like and was a control row's finding. `a` and
// `static a` are two SYMBOLS — the binder declares one into the class's members
// and the other into its exports — so each has a single declaration and
// `len(Declarations) > 1` fails before the map choice is ever made. Folding
// instanceNames and staticNames into one map leaves this file silent;
// checker_class_duplicate_both_sides.ts is the shape that sees it.
export {};
class C {
    a: number = 1;
    static a: string = "x";
}
