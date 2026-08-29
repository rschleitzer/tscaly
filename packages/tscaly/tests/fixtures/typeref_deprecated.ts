// Slice 95's deprecation half. `checkTypeReferenceOrImport`'s tail asks whether
// any declaration of the resolved symbol is a TYPE declaration carrying an
// `@deprecated` JSDoc tag, and answers with a SUGGESTION diagnostic — which goes
// to a second list `GetDiagnostics` never reads.
//
// ★★ SO THIS FIXTURE PINS A COUNTER AND NOT A LINE, and that is the honest
// description: the C section is EMPTY on both sides here, in both directions, and
// would be empty just as well if the whole branch were deleted. What it is for is
// the control battery — `suggestion_count` is the one thing that moves.
declare namespace N {
    /** @deprecated use Bar */
    interface Foo { a: number; }
    interface Bar { b: number; }
    let f: Foo;
    let g: Bar;
}
