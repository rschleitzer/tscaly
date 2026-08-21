// slice 42 — JSDeclarationKindThisProperty, the fourth assignment-declaration
// kind and the only one that declares into a CLASS rather than into a file's or an
// entity's exports: `this.a = 1` in a JavaScript constructor declares `a` as a
// MEMBER of the class, with Property|Assignment, exactly as though the class had
// written the field.
//
// ★ The declaring node is the whole BinaryExpression, not its left side, so the
// symbol's declaration span covers `this.a = 1` — which is what makes the
// assignment visible as a declaration at all.
//
// ★★ Two of them merge onto ONE symbol when the name repeats, and the second
// assignment adds a second declaration rather than a second symbol. That is the
// ordinary declareSymbol merge and it is only reachable here because Assignment
// declarations may merge with each other.
// @Filename: this1.js
class C {
    constructor() {
        this.a = 1;
        this.b = 2;
        this.a = 3;
    }
}
