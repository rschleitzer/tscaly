// slice 37 — JSDeclarationKindModuleExports. `module.exports = x` in a JavaScript
// file makes the file a CommonJS module: the file gets a module symbol named
// after its own path (bindSourceFileAsExternalModule, the same symbol an
// `import` would have produced), the assignment declares the unprefixed
// `export=` into that symbol's exports, and the tail of bindContainer declares
// the two locals `module` and `exports` — `module` with a member called
// `exports`, so that `module.exports` resolves through a symbol.
//
// The RIGHT operand decides the symbol's flags: an entity-name expression or a
// class expression is an Alias, anything else a Property.
// @Filename: mod.js
module.exports = 1;
