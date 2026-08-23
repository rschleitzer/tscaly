// Slice 59. checkCollisionWithGlobalPromiseInGeneratedCode's guard, and the
// fixture is a PIN rather than a diagnostic.
//
// ★★★ THE GUARD IS `languageVersion >= ScriptTargetES2017` AND THE TARGET IS
// ES2025, so the function returns at its first line and nothing here is ever
// reported. What the fixture witnesses is the unported TAG the check would leave
// if the target were lower — `check-collision-with-global-promise` — which is
// visible through the battery's pin and through no yardstick at all.
//
// ★★ WHAT STANDS BEHIND THE GUARD IS A BINDER FLAG THIS PORT DOES NOT SET:
// NodeFlagsHasAsyncFunctions, left out of bind_function_declaration and
// bind_function_expression with the argument *no dump here can see it*. This
// slice is the reader those two notes asked for, and it arrives behind a closed
// guard — so the flag stays unobservable and both notes stay true.
class Promise {}
