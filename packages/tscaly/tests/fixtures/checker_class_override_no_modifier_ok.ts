// Slice 74. The negative for the fixture beside it: the same class with the
// modifier removed reports NOTHING. `hasOverrideModifier` is the whole trigger,
// and with no base type there is no other question to ask — the reference's
// `!memberHasOverrideModifier && !NoImplicitOverride.IsTrue()` return is not even
// reached, because the nil-base branch has already returned.
export {};
class C {
    foo(): void {}
}
