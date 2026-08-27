// Slice 74. A STATIC member, and the point is that nothing filters on static
// here. checkMembersForOverrideModifier walks every non-ambient member and
// checkMemberForOverrideModifier's nil-base branch asks only for the modifier —
// `memberIsStatic` is read further down, in the half a base type is needed for.
export {};
class C {
    static override s: number = 1;
}
