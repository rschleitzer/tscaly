// Slice 101: The assignment operator's own site — the third of the three this slice wires,
// and the only one whose target type is REWRITTEN before the comparison: a
// compound assignment to a property access is asked about the WRITE type.
var s: string = "a";
var n: number = 1;
s = "b";
s = 1;
n += 1;
