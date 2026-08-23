// Slice 59. The class-like arm's SECOND new call: checkTypeParameters, which the
// collision head unblocked.
//
// ★★ THE FORK IS WHY THIS FIXTURE EXISTS. checkTypeParameters reports from INSIDE
// its loop, so a plain class walks past it to checkExportsOnMergedDeclarations
// while a GENERIC one stops at check-type-parameter — the same shape slice 52
// measured for the function declaration. Only the tag distinguishes them, so only
// the battery's pin can see it.
class C<T> {}
