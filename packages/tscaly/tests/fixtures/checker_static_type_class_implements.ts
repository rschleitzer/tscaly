// A class with an `implements` clause and no `extends`, so
// getBaseTypeNodeOfClass must answer NOTHING and the class takes
// getBaseConstructorTypeOfClass' undefinedType early return — the same tag as a
// bare class.
//
// ★★★ IT EXISTS TO RETIRE AN ARGUMENT SLICE 66 COULD NOT MEASURE. Its g11 broke
// the EXTENDS-token test inside the heritage walk and came back ungated, with a
// proof rather than a corpus gap: "the only caller is isThislessInterface, which
// is only ever asked about an INTERFACE, and an interface cannot carry an
// `implements` clause — so the token test cannot distinguish anything until a
// class asks". Slice 67 is the class asking. With that test broken the walk
// hands this class its `implements` element as a base and the tag moves to
// check-expression, which is what turns the argument into a row.
//
// ★ `Shape` is declared after `P` because record_unported is first-wins per unit
// and interfaces hoist.
class P implements Shape {
    a: string;
}
interface Shape {
    a: string;
}
