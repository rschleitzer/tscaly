// Slice 64. TS1106, and the reason it is a TEXT comparison rather than a token test.
//
// ★★★ `async` IS NOT A KEYWORD IN THIS POSITION. `for (async of [])` parses as a
// for-of whose initializer is an ordinary Identifier spelled `async`, so there is no
// AsyncKeyword to ask about and the reference compares `Initializer.Text() ==
// "async"`. It is asked only outside an await context, which is why the second line
// — the same spelling with a declaration in front of it — reports nothing: `let` makes
// the initializer a VariableDeclarationList and the test never runs.
for (async of []) { }
for (let async of []) { }
