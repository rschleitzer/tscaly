// What this chapter can answer is decided by the CALLEE (slice 89). `(1)()` is
// the shape whose callee HAS a type in this port — a fresh number literal — so
// resolveCallExpression gets past its `checkExpression(node.Expression())` and
// stops one line later at checkNonNullTypeWithReporter, i.e. at getTypeFacts.
// `new (1)()` reaches the same wall one wrapper down, through
// resolveNewExpression's checkNonNullExpression. Every ordinary call in the
// corpus stops EARLIER than this, at the identifier the callee is.
(1)();
new (1)();
