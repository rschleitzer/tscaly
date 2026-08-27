// Slice 73. An `accessor` field counts as an ACCESSOR and not as a property.
//
// ★★★ IT IS THE ONLY WITNESS FOR HasAccessorModifier IN EITHER BRANCH. The
// reference's first condition is `IsPropertyDeclaration && !HasAccessorModifier`
// and its second `IsAccessor || IsPropertyDeclaration && HasAccessorModifier`, so
// one kind reaches both branches and the modifier is what picks. A port that
// dropped the modifier test would send `accessor a` down the property branch with
// kind 1 — which still reports here, since 1 against state 1 reports too, so this
// file needs its partner: checker_class_accessor_modifier_pair_ok.ts, where the
// wrong reading reports and the right one does not.
export {};
class C {
    a: number = 1;
    accessor a: number = 2;
}
