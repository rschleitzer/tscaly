// A catch clause's binding routes through parseVariableDeclaration, so it takes
// the pattern for free — and it is the one caller that passes
// allowExclamation=FALSE, which is what parser_catch_exclamation pins from the
// other side.
try { } catch ([a]) { }
try { } catch ({ b }) { }
try { } catch ({ c: [d] }) { }
