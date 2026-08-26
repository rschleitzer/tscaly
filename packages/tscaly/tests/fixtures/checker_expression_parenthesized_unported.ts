// The parenthesis is TRANSPARENT to the work list: this unit stops at
// `check-binary-expression 227`, not at a row naming the ParenthesizedExpression
// it is wrapped in. The tag names the first thing not implemented however deep it
// sits, which is the property every statement arm in this file already has.
//
// ★ The file holds ONE statement on purpose. An earlier draft declared `var x:
// number` to make the operand resolvable, and the tag then read
// `check-var-declared-names-not-shadowed` — the DECLARATION reported first, and
// first-wins meant the file measured something else entirely. The dispatch needs
// no resolvable operand to answer, so the declaration was the whole mistake.
(1 + 1);
