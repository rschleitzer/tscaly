// `tokenIsIdentifier` is captured BEFORE the property name is parsed. Ask it
// after and the token is whatever FOLLOWS the name, which is a different
// question: `{ a }` would demand a colon.
var { a } = x;
var { b: c } = x;
