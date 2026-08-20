// slice 37 — the fourth negative of IsVariableDeclarationInitializedToRequire:
// `node.Parent.Parent.ModifierFlags() & Export`, read off the variable STATEMENT
// two levels up rather than off the declaration. So `x` is a
// FunctionScopedVariable and not an Alias.
//
// The `export` also makes the file an ES module, which is the second thing this
// fixture shows: setCommonJSModuleIndicator refuses, so the `require` call
// declares no `module`/`exports` locals even though it is a JavaScript file.
// @Filename: reqexp.js
export const x = require("./x");
