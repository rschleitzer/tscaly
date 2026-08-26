// ★★★ THE PARSER FIELD THIS SLICE MADE NECESSARY. reportImplicitAny returns
// without a word in a JavaScript file unless checkJs is on for it, and checkJs is
// unset under this harness — so the whole answer is the `@ts-check` directive,
// which the parser used to recognise and DROP under a note naming the checker as
// its reader.
// @ts-check
function f(a) { }
