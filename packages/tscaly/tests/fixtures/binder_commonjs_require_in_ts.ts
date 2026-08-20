// slice 37 — bindCallExpression's IsInJSFile gate. `require("m")` in a
// TypeScript file is an ordinary call: the file does NOT become a CommonJS
// module, so it gets no module symbol and no `module`/`exports` locals. That is
// the same asymmetry GetAssignmentDeclarationKind has for the first three kinds
// and does NOT have for `Property`.
require("m");
