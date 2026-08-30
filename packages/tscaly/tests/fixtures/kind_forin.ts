// Slice 102: The for-in statement's right-hand side — TS2407, the second and last
// isTypeAssignableToKind call site.
declare var o: object;
for (var k1 in o) { }
for (var k2 in 1) { }
for (var k3 in "a") { }
for (var k4 in true) { }
