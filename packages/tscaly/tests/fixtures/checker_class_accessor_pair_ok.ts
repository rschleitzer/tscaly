// Slice 73. A getter and a setter of one name are NOT a duplicate, and this file
// is the negative that makes the `kind != 2` conjunct load-bearing rather than
// decorative.
//
// ★★★ THE SYMBOL HAS TWO DECLARATIONS HERE, so the guard `len(Declarations) > 1`
// passes and the state machine really runs: the getter writes 2 and the setter
// arrives with kind 2 against state 2, the one combination that falls through
// both cases of the reference's switch. A port that reported on any second
// sighting would produce two diagnostics on a shape every TypeScript program has.
export {};
class C {
    get a(): number { return 1; }
    set a(v: number) {}
}
