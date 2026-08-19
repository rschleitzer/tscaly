// Several JSDoc comments on ONE node, which is why the accessor answers a LIST
// and why the dump prints a count. `pos` walks forward across them: each
// comment's own start is the END of the one before it, not the node's position.
//
// The last two are not JSDoc at all — `/**/` is excluded by the four-character
// rule and `/* */` by the second asterisk — so they must not appear.

/** first */
/** second */
/** third */
var a;

/**/
/* ordinary */
/*** three stars is still JSDoc */
var b;

/***/
var c;
