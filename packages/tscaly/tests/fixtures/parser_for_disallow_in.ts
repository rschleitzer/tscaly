// A for initializer is the ONE place in the language that SETS
// DisallowInContext, and an argument-expression element CLEARS it again — so
// `a in b` here is a BinaryExpression whose flags do not carry 1 << 10 while
// the call around it does. Both halves are visible in the dump.
for (f(a in b);;) ;
for (g((c in d));;) ;
