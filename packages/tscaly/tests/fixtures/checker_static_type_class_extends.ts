// The other side of getBaseConstructorTypeOfClass: a class that HAS a base type
// node. getBaseTypeNodeOfClass answers the ExpressionWithTypeArguments, a
// resolution frame is pushed, and the reference's next statement is
// checkExpression on the base clause's expression — the whole expression
// dimension, and the reason 2.5 % of the corpus's classes stop one call earlier
// than the other 97.5 %.
//
// ★ The base is deliberately UNDECLARED. record_unported is first-wins per UNIT,
// so a `class Base {}` written above would report at its own
// checkFunctionOrConstructorSymbol and this fixture would pin that instead —
// which is what the first draft of it did.
class D extends Base {}
