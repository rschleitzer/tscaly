// Slice 51. checkGrammarTypeArguments, reached through
// checkGrammarExpressionWithTypeArguments for every type of every heritage
// clause — both disjuncts of its `||`, in that order.
//
// ★ The empty type-argument list takes the same span arithmetic as the empty type
// PARAMETER list one fixture up, against a different message; the trailing comma
// takes the one-character span. Two checks, two rows of the side table.
class A<T> {}
class C extends A<> {}
class D<T> extends A<T,> {}
