// Slice 99: the four walls of this chapter, each with the tag it raises. It is a
// CONTAINMENT fixture — nothing here is expected to answer — and it exists so that
// a control which removes one of the four reports has a file where the removal is
// visible as a tag rather than as a missing type.
//
// ★ getSpreadType, checkComputedPropertyName and
// checkFunctionExpressionOrObjectLiteralMethod are three separate chapters and the
// fourth is the contextual type of a binary operand; a control on one of them must
// not move the other three.
export {}

const base = { a: 1 }

const spread = { ...base, b: 2 }

const k = "key"
const computed = { [k]: 1 }

const method = { m() { return 1 } }

let assigned = { a: 1 }
assigned = { a: 2 }
