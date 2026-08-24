// Slice 64. checkGrammarForInOrForOfStatement's declaration-list branch, which is
// the whole of what the three loop arms share and the only part of it that is
// reachable more than once.
//
// ★★ THREE REPORTS, EACH IN TWO SPELLINGS, and the pairing is the point: the
// message is chosen by the loop's KIND and nothing else, so every line here has a
// twin one kind along. In order: two declarations (TS1091 / TS1188, on the SECOND
// declaration's first token), an initializer (TS1189 / TS1190, on the declaration's
// NAME), and a type annotation (TS2404 / TS2483, on the DECLARATION rather than on
// the name — the three sites are three different nodes and the yardstick compares
// spans).
//
// ★ Each `return`s, so a declaration list carrying two of the three faults reports
// only the first. That is the reference's own shape and is why the six lines are six
// statements rather than three.
for (var a, b in {}) { }
for (var c, d of []) { }
for (var e = 1 in {}) { }
for (var f = 1 of []) { }
for (var g: string in {}) { }
for (var h: string of []) { }
// ★★★ THE LAST TWO LINES ARE ABOUT THE THREE REPORTERS, NOT ABOUT THE THREE REPORTS,
// and they are here because a BARE IDENTIFIER cannot tell them apart. The reference
// spells the first report `grammarErrorOnFirstToken(declarations[1])` and the other
// two `grammarErrorOnNode(…)`, four lines apart — and for `var b in {}` all three
// spellings answer the same span, because error_range_for_node resolves a
// VariableDeclaration to its NAME and a bare name's first token is the name.
//
// ★★ A DESTRUCTURING NAME SEPARATES THEM. `[b2]` has a first token of `[`, one
// character, against the whole three-character pattern — so controls-slice64.sh's g03
// (the first report routed through grammar_error_on_node) is red on this line and on
// nothing else in the corpus.
//
// ★★★ AND THE SECOND OF THE TWO LINES IS THE OPPOSITE RESULT, WHICH IS WHY IT IS
// KEPT: `for (var [e2] = 1 in {})` reports TS1189 on `[e2]`, and the DECLARATION
// spelling would answer `[e2]` too — error_range_for_node's declaration-name arm makes
// `on_node(decl)` and `on_node(decl.Name())` the same range for every declaration
// there is. So g04 and g19 are UNGATED with a PROOF rather than for want of a fixture,
// and this line is what proves it rather than what would gate it.
for (var a2, [b2] in {}) { }
for (var [e2] = 1 in {}) { }
