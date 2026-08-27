// Slice 73. A parameter property spelled as a binding pattern declares no member,
// and both walks skip it — the `!ast.IsBindingPattern(param.Name())` conjunct.
//
// ★★★ THE CONJUNCT IS PROVABLY REDUNDANT HERE, AND THE PROOF IS DOUBLE — measured
// after the control row that predicted a red came back ungated. The binder gives
// such a parameter the INTERNAL name `__missing`, whose first byte is 0xFE and so
// can never equal a member's name, and it gives it ONE declaration, so the
// `len(Declarations) > 1` guard stops it before the map is read at all. Either
// reason alone makes the conjunct unobservable; it is transcribed because the
// reference has it and because a later slice that late-binds a computed name could
// remove the first reason.
//
// ★ What the file DOES pin is that nothing here reports: the field of the same
// name must stay silent, which is the observable half of the same claim.
export {};
class C {
    a: number = 1;
    constructor(public { a }: { a: number }) {}
}
