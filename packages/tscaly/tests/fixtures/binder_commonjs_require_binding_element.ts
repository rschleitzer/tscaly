// slice 37 — the BINDING ELEMENT arm of IsVariableDeclarationInitializedToRequire.
// The predicate walks from the element to Parent.Parent, so a TOP-LEVEL element
// of `const { a } = require("m")` lands on the variable declaration and is an
// Alias — and a NESTED one lands on the enclosing binding ELEMENT instead, which
// is not a variable declaration, so `c` is an ordinary FunctionScopedVariable.
// That asymmetry is the reference's, and it is what makes the walk one step
// rather than a loop.
// @Filename: reqbind.js
const { a, b: { c } } = require("./m");
const [d] = require("./n");
