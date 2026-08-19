// AstNode.expression_of answered null for an ElementAccessExpression, because
// the accessor was narrowed to the eight kinds its callers were thought to
// reach — and the reference PANICS where it answers null, so a missing arm is a
// silently wrong ANSWER rather than a crash. §3.5bk.
//
// Both readers of it here ask about exactly that kind:
// is_assignment_declaration (this[...] = ...) and
// is_module_exports_access_expression (module.exports[...] = ...). With the arm
// missing the whole @type reparse is lost: no synthesized type node hangs in
// the BinaryExpression, and the tree is otherwise identical.
// @Filename: elementaccess.js
/** @type object */ this["arguments"] = foo;
/** @type {number} */ module.exports["k"] = 1;
/** @type {string} */ this.plain = 2;
