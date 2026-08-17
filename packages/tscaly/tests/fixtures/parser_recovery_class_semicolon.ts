// The same `;` question one level in: isListElement(PCClassMembers,
// inErrorRecovery) drops its `token == ';'` arm during recovery, so a stray
// semicolon in a broken class is skipped rather than read as a member.
//
// The parameter list is what gets stuck here; the class body is the enclosing
// list that must refuse the token.
class C { m(a, ; ) {} }
