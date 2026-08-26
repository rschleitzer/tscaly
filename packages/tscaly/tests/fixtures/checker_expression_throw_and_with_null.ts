// Two statement arms that hand the type to nothing, so both are COMPLETE for a
// typed expression: the reference discards checkExpression's result in
// checkThrowStatement and in checkWithStatement alike.
//
// ★ The `with` keeps its two reports — TS2410 over the head and the async-context
// grammar error — and those are what make this file worth having: the arm reports
// AND finishes, which is a combination the port could not produce before, because
// the expression used to stop it.
throw null;
