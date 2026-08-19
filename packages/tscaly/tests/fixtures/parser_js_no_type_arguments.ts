// "TypeArguments must not be parsed in JavaScript files to avoid ambiguity with
// binary operators" — tryParseTypeArgumentsInExpression's own first line, and
// the whole of what it does here. In a JavaScript file `Foo<number>()` is two
// relational comparisons and a parenthesized expression, and the empty
// parentheses then report TS1109. Without the test the file's grammar quietly
// becomes TypeScript's for this one production. §3.5bn.
// @Filename: typeargs.jsx
Foo<number>();
const a = b < c > (d);
