// `for (using of x)` FIRST: it is the disallowOf discriminator. With the
// look-ahead's disallowOf ON, `using` is an ordinary identifier and this is a
// for-of over `x`; with it off, `using` starts a declaration list and the tree
// is a different one.
for (using of x) ;
for (using a of b) ;
for (await using c of d) ;
