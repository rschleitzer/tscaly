// The super branch of resolveCallExpression (slice 89). `super()` is a
// CallExpression whose callee is the SuperKeyword, and the reference's first line
// there is checkSuperExpression — the base constructors, resolveCall and
// resolveUntypedCall all hang off its answer. ★The row it records is the
// DISPATCH's own `check-super-expression`, which is why removing the branch
// changes nothing: checkExpression of a bare `super` lands on the same tag.
class B { constructor() { } }
class D extends B { constructor() { super(); } }
