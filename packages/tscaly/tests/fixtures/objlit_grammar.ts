// Slice 99: checkGrammarObjectLiteralExpression — the chapter's OWN diagnostics.
// Everything the member loop can produce is downstream of a type; everything here
// is syntax over the property list, and it lands whether or not the type is built.
//
// ★★ THE `{ a = 1 }` SHORTHAND IS THE ROW THAT PAID FOR ITSELF: the reference
// reports on the FIRST TOKEN FOLLOWING the last child before the initializer, and
// the last child is the `=` token — not the name. Reasoned from the slot list it
// came out two bytes early.
export {}

const dupProp = { a: 1, a: 2 }

const dupMethod = { m() { }, m() { } }

const shortInit = { a = 1 }

const propThenAccessor = { p: 1, get p() { return 1 } }

const twoGetters = { get g() { return 1 }, get g() { return 2 } }

const getterAndSetter = { get ok() { return 1 }, set ok(v) { } }
