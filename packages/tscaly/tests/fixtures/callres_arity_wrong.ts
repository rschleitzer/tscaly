// Slice 108. hasCorrectArity answering FALSE, in both directions.
//
// ★★★ THE TWO DIRECTIONS ARE DIFFERENT LINES OF THE FUNCTION and a fixture with
// only one of them leaves the other with no input: too MANY arguments is the
// `!hasEffectiveRestParameter && argCount > effectiveParameterCount` test, too FEW
// is the `argCount >= effectiveMinimumArguments` test and the void loop under it.
//
// ★★ THE REFERENCE REPORTS TS2554 ON EVERY LINE HERE AND THIS PORT REPORTS NOTHING,
// which is a LOSS and therefore invisible to diagcheck — the whole reason this
// fixture is pinned on the stop log as well.
function f(a: number, b: number): void {}
f(1);
f(1, 2, 3);

function g(): void {}
g(1);
