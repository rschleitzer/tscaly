// Slice 74. THE ORDER, and it is the reference's own: checkMembersForOverrideModifier
// runs BEFORE the implements loop, so a class with an `implements` clause reports
// TS4112 for its `override` member and only then meets the stop.
//
// ★★ THIS IS WHY THE IMPLEMENTS ROW IS BEHIND THE OVERRIDE CALL AND NOT IN FRONT
// OF IT. diagcheck compares a SUBSEQUENCE, so a port that stopped at the
// implements clause first would lose this line and stay green — the fixture is the
// only thing that says the two statements are in the right sequence.
//
// ★ The interface is DECLARED here rather than left dangling so that the C section
// is the reference's exactly: an unresolved `implements Iface` earns a TS2304 the
// port does not raise, and a pin with a documented hole in it is worth less than
// one without. The implements ROW's own witness is therefore the corpus unit, not
// this file — first-wins gives the tag to the interface above.
export {};
interface Iface { x: number }
class C implements Iface {
    override x: number = 1;
}
