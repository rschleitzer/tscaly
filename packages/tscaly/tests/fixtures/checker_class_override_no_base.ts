// Slice 74. THE CORE OF THE SLICE: a member carrying `override` in a class that
// extends nothing. checkMemberForOverrideModifier's `baseWithThis == nil` branch,
// and the only report the override family can raise while the extends heritage
// block is still a stop.
//
// ★★ THE SPAN IS THE MEMBER'S NAME, AND THAT IS NOT WHAT `c.error(member, …)`
// LOOKS LIKE IT SAYS. scanner.GetErrorRangeForNode narrows a named declaration to
// its name for a fixed list of kinds, and KindMethodDeclaration is on it — so the
// pin here is `foo`, three bytes, not the member. The fixture that shows the other
// half of that rule is the parameter-property one.
export {};
class C {
    override foo(): void {}
}
