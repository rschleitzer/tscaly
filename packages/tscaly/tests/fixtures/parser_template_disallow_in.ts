// parse_template_span calls parseExpressionAllowIn, not parseExpression: a
// substitution is bracketed by `${` and `}`, so an `in` inside it is
// unambiguous even where the enclosing context has DisallowIn set. The only
// place that sets it is a `for` initializer.
//
// With the AllowIn, `b in c` is one binary expression. Without it the
// expression stops at `b`, the `}` never arrives where it is expected, and this
// port reports unported — so this file gates by the MATCHED COUNT.
for (var a = `x${b in c}y`;;) ;

// The same for a TAGGED template, whose spans go through the same routine.
for (var d = t`x${e in f}y`;;) ;
