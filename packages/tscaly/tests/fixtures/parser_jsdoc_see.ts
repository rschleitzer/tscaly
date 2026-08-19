// @see, whose name-reference test is three clauses and reads the SOURCE for one
// of them: a bare identifier is a name UNLESS the text right after it is `://`,
// which is what keeps a URL from being parsed as a reference.
//
// No corpus unit contains a @see tag.

/** @see Alpha */
var a;

/** @see {Beta.gamma} */
var b;

/** @see http://example.com/x */
var c;

/** @see */
var d;
