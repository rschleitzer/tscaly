// slice 38 — the deferred expando pass, plainest shape. `f.a = 1` after
// `function f() {}` is JSDeclarationKindProperty, and the pass declares `a` into
// the FUNCTION symbol's exports with Property|Assignment.
//
// ★ It is not JavaScript-only: GetAssignmentDeclarationKind's Property arm sits
// outside its IsInJSFile test, so this whole file is TypeScript and every
// assignment below is still an expando declaration.
//
// Three claims in four lines: the property is declared at all; two assignments to
// ONE name MERGE into one symbol with two declarations (both carry Assignment, so
// the reference's "no non-expando declarations for that name" test admits the
// second); and the host symbol is the function's own, not a new one.
function f() {}
f.a = 1;
f.a = 2;
f.b = 3;
