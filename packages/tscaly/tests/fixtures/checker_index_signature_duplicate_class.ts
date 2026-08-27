// SLICE 77: the same report through the CLASS arm, which reaches it down a
// completely different path — past the extends and implements stops, past
// checkMembersForOverrideModifier, and past the two checkIndexConstraints calls
// this slice deliberately leaves as a stop.
//
// * A class with no `extends` and no `implements`, because slice 74 measured that
// either clause returns before the tail.
class C { [k: string]: any; [j: string]: any; }
