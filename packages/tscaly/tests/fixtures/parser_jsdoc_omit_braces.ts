// The two tags whose type may be written WITHOUT braces — parseJSDocTypeExpression's
// `mayOmitBraces`. Everywhere else a missing `{` is reported.

/** @type string */
var a;

/** @this Foo */
function b() { }
