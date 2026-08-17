// The `;` that error recovery must NOT take for a statement.
//
// isListElement(PCSourceElements, inErrorRecovery) answers
// `!(token == ';' && inErrorRecovery) && isStartOfStatement()`. Here the enum
// member list is stuck on the `;`, so it asks every OPEN list whether that
// token is one of theirs — and the top-level statement list must say NO, or the
// enum gives up and the `;` is reported twice.
enum E { ; }
