// `{@link Foo#bar}` — the one shape that reaches ReScanHashToken. The link NAME
// is read with the ORDINARY parser, so `#bar` arrives as a single
// PrivateIdentifier token and has to be split back into a `#` and a name.
//
// It is its own fixture rather than a line of parser_jsdoc_link.ts because the
// routine it gates was MISSING when that fixture was written and the compiler
// said nothing: a member call on a FIELD is dropped silently. A fixture per
// claim is what turns that from a lucky catch into a gate.

/** {@link Alpha#beta} */
var a;

/** {@linkcode Gamma.delta#epsilon} */
var b;
