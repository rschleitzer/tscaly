// slice 42 — the DYNAMIC name, which is the `isComputedName` half of
// declareSymbolEx and the one place this port passes that flag at all. A
// `this[k()] = 1` has no name to declare, so the reference declares the anonymous
// `%FEcomputed` one into the class's table and remembers the NODE on the class for
// the checker to bind late.
//
// ★★ Two things differ from the static-name arm and both are visible: the flags
// carry NO Assignment (Property alone, plus the replaceable mark), and a second
// symbol appears — `%FEassignment`, in the class's EXPORTS, holding this
// assignment as a declaration. That symbol is a list, not a declaration of
// anything: addLateBoundAssignmentDeclarationToSymbol appends RAW, so two dynamic
// assignments give it two declarations.
//
// ★ `k()` and not `k`: an element access with a plain identifier argument is not a
// dynamic name — HasDynamicName asks whether the name is a computed one that is
// not a literal, and a CALL is what makes it late-bound.
// @Filename: thiscomputed.js
const k = "dyn";

class C {
    constructor() {
        this[k()] = 1;
    }
}
