// @throws and its synonym @exception. Its type expression is OPTIONAL — the
// tryParseTypeExpression route, which needs a `{` and answers null without one —
// where @type and @satisfies require one.
//
// No corpus unit contains either spelling.

/** @throws {Error} when it goes wrong */
function a() { }

/** @exception {TypeError} */
function b() { }

/** @throws it can just say so */
function c() { }
