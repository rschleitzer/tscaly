// SLICE 76: the same finish through the other two bits of NodeFlagsBlockScoped —
// Let|Const|Using — because a guard exercised through ONE of its three bits is a
// guard two thirds untested.
//
// ★★ AND THE ROW THAT SHOULD HAVE PROVEN THAT CAME BACK UNGATED (control g04,
// which narrows the mask to Let alone): a const's symbol is
// SymbolFlagsBlockScopedVariable too, so the symbol test catches what the narrowed
// mask lets through. The mask's three bits are not separable by any fixture here —
// see checker_var_shadow_let_inert.ts for the general form of the finding.
//
// * `declare` and not an initializer, because a const's initializer would stop at
// check-type-assignable-to two statements earlier and the file would gate that row
// instead of this one (slice 72's one-mechanism-per-file rule).
declare const z: string;
