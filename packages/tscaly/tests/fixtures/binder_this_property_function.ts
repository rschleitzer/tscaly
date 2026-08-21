// slice 42 — the two kinds that get NOTHING, deliberately. getThisClassAndSymbolTable
// has arms for FunctionDeclaration and FunctionExpression whose bodies are
// upstream's own `// !!! constructor functions`, i.e. empty — so a `this.a = 1` in
// a plain function answers no table, and bindThisPropertyAssignment's `else if`
// lets exactly those two through without the panic that every other tableless
// kind gets.
//
// ★★ So this fixture pins an ABSENCE, and the absence has two halves that a
// single blank answer cannot tell apart: the two arms being empty, and the two
// kinds being exempt from the unhandled case. The marker is what would fire if
// the exemption were dropped.
//
// ★ The top-level assignment is a third route to the same nothing, and the
// cheapest one: a SourceFile is not a this-container at all, so `thisContainer`
// is still null and the arm's third guard returns.
// @Filename: thisfn.js
this.topLevel = 1;

function f() {
    this.inFunctionDeclaration = 1;
}

const g = function () {
    this.inFunctionExpression = 1;
};
