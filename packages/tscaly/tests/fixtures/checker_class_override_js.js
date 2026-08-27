// Slice 74. The `isJs` term: in a JavaScript file the same branch reports TS4121
// instead of TS4112, and the two codes are what makes the term gateable rather
// than transcribed on faith.
//
// ★ `hasOverrideModifier` is HasSyntacticModifier and NOT the effective,
// JSDoc-aware form — so what this fixture needs is the `override` KEYWORD in a
// `.js` unit, not an `@override` tag.
export {};
class C {
    override foo() {}
}
