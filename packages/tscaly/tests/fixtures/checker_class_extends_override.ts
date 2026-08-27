// Slice 74. THE PRICE OF THE EXTENDS STOP, written as a fixture rather than as a
// sentence. A class with a base and an `override` member is where the reference
// reports TS4113 — *not declared in the base class* — and this port reports
// nothing at all: the walk returns at the extends heritage block, one statement
// before checkMembersForOverrideModifier.
//
// ★★ SO THE PIN HERE IS AN EMPTY C SECTION, and the day the extends block becomes
// a port this fixture is the one that must gain a line. That is a better record of
// the stop than a comment, because it is compared on every run.
export {};
class B {}
class C extends B {
    override x: number = 1;
}
