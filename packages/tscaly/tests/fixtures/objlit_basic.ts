// Slice 99: the object literal's ordinary shape — the property-assignment family
// and the anonymous type it builds. Every member here reaches the loop's first
// arm, so this file is what the OBJPIN's four numeric columns are read on.
//
// ★ The nested literal is not decoration: its own contextual type is asked
// through getContextualTypeForObjectLiteralElement, whose reference body answers
// NIL when the outer literal has none — which is the arm that decides whether
// this chapter yields at all.
export {}

const plain = { a: 1, b: "two", c: true }

const empty = {}

const nested = { outer: { inner: 1 }, sibling: 2 }

const a = 1
const b = 2
const shorthand = { a, b }

const quoted = { "s": 1, 3: 2, 0x4: 3 }

const keywords = { default: 1, in: 2, function: 3 }

const trailing = { a: 1, }

// An annotated member: the reference reads the annotation instead of the
// initializer's type and compares the two, which is checkTypeAssignableTo.
const annotated = { m: 1 }

// ★★ THE PROPAGATION TERM'S CONTAINMENT PROOF, and it is the reverse of what this
// line was written to show. `objectFlags |= t.objectFlags & PropagatingFlags` can
// only move on a member whose type carries one of the three bits, and the only one
// reachable here would be ContainsWideningType — which createWideningType does NOT
// set under strictNullChecks: its whole body is `if strictNullChecks { return
// nonWideningType }`, and the option is on. So `null` here answers the plain null
// type and the OR is a no-op, measured rather than assumed.
const widening = { w: null }
