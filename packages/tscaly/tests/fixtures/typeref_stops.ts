// Slice 95's four STOPS, one per name, and the fixture exists so each of them is
// a row a control can move rather than a sentence in a comment. The names are
// UNQUALIFIED where the stop is about the type and QUALIFIED where the stop is
// about the name, because the qualified-name arm returns before any of the others
// is reached — six qualified references measure ONE row, not six.
//
//   Al           get-type-from-type-alias-reference — getDeclaredTypeOfTypeAlias
//   E            get-declared-type-of-enum        — already a stop one chapter down
//   N.Foo        resolve-entity-name              — the QUALIFIED name, whose left
//                                                   resolves with the NAMESPACE
//                                                   meaning and then reads that
//                                                   namespace's exports
//   Missing      resolve-name-not-found           — the globals table (§3.11), and
//                                                   the row this slice makes the
//                                                   corpus head
declare namespace N {
    interface Foo { a: number; }
    type Al = number;
    enum E { A }
    let a: Al;
    let b: E;
    let c: Missing;
}
declare namespace M {
    let d: N.Foo;
}
