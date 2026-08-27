// SLICE 77: the `never` arm of Distributed(), and it is LOAD-BEARING rather than
// transcription for its own sake. `Distributed()` answers the EMPTY list for
// never, so two `[k: never]` signatures contribute no group at all and the
// reference reports nothing; a port that filed never under its own type id would
// report TS2374 twice here — an INVENTION, which is the one direction diagcheck
// can see.
//
// * The unit's unported tag is `check-grammar-index-signature` and not this
// chapter's, because an index signature whose parameter is not string/number/
// symbol is a grammar error two chapters earlier. That does not stop the walk —
// record_unported marks and does not abort — so the file still exercises the arm.
//
// * What the REFERENCE says here is two TS1268 lines and NO TS2374, and this port
// says nothing at all: the two 1268s are that grammar chapter's, and our empty C
// section is a subsequence of the reference's. So the file is a negative control
// for the arm and a LOSS for the grammar row, which is the honest reading of a
// subsequence relation and is why the row is named here.
interface N { [k: never]: any; [j: never]: any; }
