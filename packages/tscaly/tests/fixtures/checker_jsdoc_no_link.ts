// SLICE 78: the gate that used to be the flag. Every construct here carries a
// plain doc comment, so NodeFlagsHasJSDoc is set on all of them and the old gate
// stopped the unit at the first one — while the reference's own loop over
// EagerJSDoc is entered ZERO times for a comment with no @see and no @link.
//
// So each arm must run and each report must appear.
/** The interface. */
interface I { [k: string]: any; [j: string]: any; }
