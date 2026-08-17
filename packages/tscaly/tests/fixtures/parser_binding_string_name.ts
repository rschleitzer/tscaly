// A non-identifier property name takes the COLON path unconditionally:
// isBindingIdentifier() is false for a string or numeric literal, so there is
// no shorthand reading to fall into and the propertyName slot is filled.
var { "a": b } = x;
var { 0: c } = x;
// A KEYWORD is an identifier-NAME but not a binding identifier, so it reaches
// the same colon path: isLiteralPropertyName admits it into the list,
// isBindingIdentifier refuses the shorthand reading.
var { if: d } = x;
