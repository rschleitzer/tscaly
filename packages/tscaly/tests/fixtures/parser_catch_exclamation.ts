// PERMANENTLY UNPORTED, and a red-producing control.
//
// A catch clause's binding goes through parseVariableDeclaration — the
// allowExclamation=FALSE entry point — so the `!` is not an exclamation token
// here and the reference reports a missing `)`. Let it through and our side
// completes a tree the reference does not have.
try { } catch (e!) { }
