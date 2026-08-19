// Slice 24 — the PARAMETER-MODIFIER arm, which is the only one that reports at
// a MODIFIER LIST's range rather than at a node's. That range is not derivable
// from the elements (see the list_ranges side table), so this fixture is what
// makes the table observable at all.
//
// ★ A decorator alone is NOT a parameter modifier — core.Some asks IsModifier —
// so the second constructor must report nothing from this arm.
// @Filename: param_modifiers.js
class C {
    constructor(private x, readonly y) {}
}

class D {
    constructor(@dec z) {}
}
