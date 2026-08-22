// Slice 53. A `using` declaration that passes all three guards of the using fork
// — the negative control for the two fixtures beside it.
//
// ★★ IT SEPARATES `is_using` FROM WHAT IS DONE WITH IT. The fork is entered (the
// list carries NodeFlagsUsing), the for-in test fails, the ambient test fails, the
// case/default test fails, the await test fails, and the function answers false —
// so nothing is reported and the walk goes on into the declaration. A port that
// reported on entering the fork rather than on one of its three conditions would
// light up on exactly this line and on nothing in the corpus.
using c = null;
