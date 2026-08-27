// Slice 74. A PARAMETER PROPERTY, which declares a class member without appearing
// in the member list — so the constructor's parameters stand in for it, exactly
// as in slice 73's duplicate-member walk.
//
// ★★ THE REPORT IS ON THE PARAMETER, NOT ON THE CONSTRUCTOR. The recursive call
// passes `param` as the member, so a walk that handed the constructor down would
// report once, at the wrong place, and would look identical in a count.
//
// ★★★ AND THIS IS THE ONE PIN WHOSE SPAN IS THE WHOLE NODE: KindParameter is NOT
// on scanner.GetErrorRangeForNode's narrowing list — whose own comment upstream
// reads *"This list is a work in progress"* — so the range is
// `override readonly x: number`, modifiers included, where every other reporting
// fixture here pins a bare name. It is therefore the only file in the battery that
// can tell `member` from `member.Name()` apart (control g18).
export {};
class C {
    constructor(override readonly x: number) {}
}
