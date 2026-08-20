// slice 37 — the alias arm of bindModuleExportsAssignment. ExpressionIsAlias is
// `IsEntityNameExpression || IsClassExpression`, so the `export=` symbol here is
// an Alias rather than a Property. Two assignments merge — the excludes of this
// arm are 0, unlike the exports-property arm's — so the symbol carries both
// declarations and the second one wins the value declaration only if it is not
// an assignment declaration, which it is.
// @Filename: alias.js
function f() {}
module.exports = f;
module.exports = class {};
