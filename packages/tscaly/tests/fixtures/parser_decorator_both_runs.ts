// BOTH runs at once — leading decorators, a leading modifier, trailing
// decorators. The reference admits it and leaves the illegality to the checker,
// so all three land in one list in source order and there is no diagnostic.
//
// This is the shape the hasLeadingModifier / hasTrailingDecorator pair exists
// for, and the only one that separates them from a single flag: set
// hasTrailingDecorator unconditionally and the leading `@d` already closes the
// decorator arm, so the second one is never taken.
declare const d: any;

@d export @d class C { }
