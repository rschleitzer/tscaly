// slice 40 — THE FALL-THROUGH, and it is the claim slice 39 wrote down at the
// `return` this slice removed: the reference's parameter-property test sits AFTER
// the if/else, so a destructured constructor parameter carrying an accessibility
// modifier declares the class property too.
//
// ★★ What that property is NAMED is the surprise, and it is why the fixture is
// worth its own unit: declare_symbol asks get_declaration_name of the same node
// and gets a BINDING PATTERN, which is not a property-name literal — so the name
// is the internal `missing` one and the symbol lands in NO table. One node, two
// symbols, the anonymous `__0` and a nameless property, and the second one is
// what node.symbol ends up pointing at.
//
// ★★★ SO THE `__0` IS INVISIBLE HERE, AND THE COUNTER IS THE ONLY THING THAT SEES
// IT. The dump names a symbol by the declaration that owns it and by the tables
// that hold it, and after the property overwrites node.symbol the anonymous
// parameter symbol has neither — the two `%FEmissing` lines are all class A
// shows. What witnesses the pair is the file's symbol COUNTER: 18 symbols against
// 16 named lines, the difference being A's two anonymous parameters, and the
// reference answers 18 too. A slice that dropped the anonymous declaration
// entirely for a parameter property would match every line of this dump and miss
// that number.
//
// ★ Every line here is a grammar error the checker reports (a parameter property
// may not be destructured) and the binder does not. The parse is identical on
// both sides, so the unit measures the bind alone — the same argument
// binder_parameter_property_not_constructor.ts makes.
class A {
    constructor(public { a }: { a: number }, private [b]: number[]) {}
}

// ★ And the plain destructured constructor parameter beside it: no modifier, no
// property, so exactly one symbol comes out of it.
class B {
    constructor({ c }: { c: number }) {}
}
