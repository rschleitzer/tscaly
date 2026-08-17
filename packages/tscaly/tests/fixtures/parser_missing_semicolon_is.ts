// parseErrorForMissingSemicolonAfter's `is` arm. Its span ends at the CURRENT
// token's start rather than at the identifier's end, so it covers the whole
// predicate that was written where one may not be.
is T
