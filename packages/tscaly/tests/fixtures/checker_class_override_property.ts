// Slice 74. A PROPERTY rather than a method, and the walk does not distinguish
// them: every class element that is not a constructor goes to
// checkMemberForOverrideModifier as itself.
//
// ★ The span is `x`, because KindPropertyDeclaration is on
// scanner.GetErrorRangeForNode's narrowing list too. So this file and the method
// one pin the same rule at two kinds; what neither of them can show is the kind
// that is NOT on the list.
export {};
class C {
    override x: number = 1;
}
