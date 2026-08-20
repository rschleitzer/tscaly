// slice 37 — IsVariableDeclarationInitializedToRequire, which was a stand-in
// answering `false` until this slice and could not be seen while every unit that
// carries one was parked at the `commonjs-require` marker.
//
// `a` is an Alias. The three that follow are three of the predicate's negatives,
// each a FunctionScopedVariable instead:
//   b  the declaration has a TYPE — in a JavaScript file `@type` is a real
//      annotation, which the JSDoc reparser writes into the type slot
//   c  the call has no argument at all
//   d  the argument is not a string literal, and this reading of IsRequireCall
//      passes requireStringLiteralLikeArgument TRUE
//
// The fourth negative — an `export` modifier on the statement — needs a file that
// is an ES module, which would change every other answer here, so it has a
// fixture of its own.
// @Filename: reqvar.js
const a = require("./a");
/** @type {any} */
const b = require("./b");
const c = require();
const d = require(a);
