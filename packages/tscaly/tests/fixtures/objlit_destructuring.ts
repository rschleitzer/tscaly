// Slice 99: the literal as an ASSIGNMENT TARGET. `inDestructuringPattern` changes
// four things at once — the grammar check's rest-element rule, the default-value
// path that makes a property optional, the shorthand's own initializer arm, and
// the patternForType entry the resulting type gets.
//
// ★★★ AND IT IS A CONTAINMENT FIXTURE, WHICH IS NOT WHAT IT WAS WRITTEN TO BE: a
// literal that IS an assignment target never reaches checkObjectLiteral at all —
// checkBinaryExpression sends it to checkDestructuringAssignment, which this port
// stops at. So `inDestructuringPattern` is FALSE for every literal this chapter
// sees, all four of the paths above are written from the reference with no input,
// and the only row this file produces is the ordinary `source` literal.
export {}

let x = 0
let y = 0

const source = { x: 1, y: 2 }

;({ x, y } = source)

;({ x = 5, y = 6 } = source)

// ★ The duplicate-name check is SKIPPED inside a destructuring pattern, and this
// is the only line in the corpus that says so: outside one, `{ x, x }` is
// TS2783/TS1117 and here it is nothing at all.
;({ x, x } = source)
