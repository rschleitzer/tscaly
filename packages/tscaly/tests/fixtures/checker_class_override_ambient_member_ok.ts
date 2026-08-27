// Slice 74. `ast.HasAmbientModifier(member)` skips the member outright, so a
// `declare` field carrying `override` collects nothing from this family.
//
// ★★ THE REFERENCE ALSO REPORTS TS1243 HERE — *'declare' modifier cannot be used
// with 'override' modifier* — and this port does not, because that report comes
// from checkGrammarModifiers over a CLASS MEMBER and the members of a class are
// still behind check_class_declaration's stop (its own note says so). diagcheck
// compares a subsequence, so the missing line is legal; it is named here because a
// fixture whose C section is shorter than the reference's owes the reason.
export {};
class C {
    declare override x: number;
}
