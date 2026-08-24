// Slice 64. checkForInStatement's one live report, TS2491, which the reference
// emits from TWO sites with one message.
//
// ★★ THE TWO SITES ARE NOT INTERCHANGEABLE. The first is inside the
// declaration-list branch and reports on the first declaration's NAME; the second is
// in the expression branch and reports on the INITIALIZER expression itself. A port
// that hoisted the message to one site would put half of these diagnostics on the
// wrong node, and diagcheck compares spans.
//
// ★★★ THE EXPRESSION BRANCH IS AN else-CHAIN AND ONLY ITS FIRST ARM IS OURS. After
// the literal test come `isTypeAssignableTo` (TS2405) and checkReferenceExpression
// (TS2406, TS2780), both behind the type system — so the last line here is a unit
// whose reference answer holds a diagnostic this port cannot produce, and diagcheck
// stays green because a missing line is what a SUBSEQUENCE forgives.
for (var [x] in {}) { }
for (var { y } in {}) { }
for ([z] in {}) { }
for ({ w } in {}) { }
for (1 in {}) { }
