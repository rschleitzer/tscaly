// slice 37 — JSDeclarationKindExportsProperty, both spellings. `exports.a` and
// `module.exports.b` are the same kind through the same arm, and each declares a
// FUNCTION-SCOPED VARIABLE into the file symbol's exports.
//
// The element-access spelling is admitted too, because
// GetElementOrPropertyAccessName answers a string or numeric literal argument —
// so `exports[4]` declares the symbol `4`, named by the literal's VALUE.
//
// The repeated `exports.a` MERGES rather than colliding, and that is the arm's
// excludes read correctly: FunctionScopedVariableExcludes does not contain
// FunctionScopedVariable, exactly as two `var a` merge.
// @Filename: props.js
exports.a = 1;
module.exports.b = 2;
exports["c"] = 3;
exports[4] = 4;
exports.a = 5;
