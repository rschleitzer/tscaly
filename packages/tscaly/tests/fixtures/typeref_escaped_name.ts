// Slice 95's printer reads the declaration's SOURCE TEXT and not the identifier's
// scanned text, and this fixture is the only shape in which the two differ.
//
// `scanner.DeclarationNameToString` is `GetTextOfNode`, i.e. the bytes between the
// name's trivia-skipped start and its end — so a name written with a unicode
// escape prints AS WRITTEN. The scanned `Text()` of the same identifier is the
// decoded `Foo`, which is what a port that reached for the nearest accessor would
// print. Both are well-formed names; only one of them is the reference's, and the
// TYPEREF PIN is the only instrument in this directory that can tell them apart.
declare namespace N {
    interface \u0046oo { a: number; }
    interface Bar { b: number; }
    let f: \u0046oo;
    let g: Foo;
    let h: Bar;
}
