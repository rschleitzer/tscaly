// Slice 73. TS2804 — a private name used once on an instance and once statically.
//
// ★★★ THE THIRD MAP IS A BITSET AND NOT A KIND, which is the whole reason it is a
// third map: `#x` and `static #x` are two SYMBOLS with one declaration each, so
// the two kind maps never see them (the `len(Declarations) > 1` guard fails), and
// `privateNames` is keyed by the shared NAME with no static/instance split at all.
// 1 for the instance, 2 for the static, and the report fires the moment the OR
// reaches 3 — on arrival, not on a later pass.
//
// ★★ `checkStatic` is false on this report, so both members collect a diagnostic
// although they differ in staticness — the opposite of what
// checker_class_duplicate_static.ts gates.
export {};
class C {
    #x: number = 1;
    static #x: number = 2;
}
