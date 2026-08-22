// Slice 51. checkGrammarExpressionWithTypeArguments' FIRST branch — the one that
// is not a list-range question: `import` as the expression of an
// ExpressionWithTypeArguments that carries type arguments.
//
// ★ It reports through grammarErrorOnNode, i.e. the error RANGE, not the list and
// not the first token — so it is also the one report of this slice whose span
// comes from the binder's error_range_for_node rather than from a scan or a row.
class C extends import<T> {}
