// An AMBIENT unit with no statements, which is the guard in
// Checker.check_grammar_source_file: `node.Flags&Ambient != 0 &&
// checkGrammarTopLevelElementsForRequiredDeclareModifier(node)`, whose second half
// needs ast.IsDeclarationNode and therefore reports. The report is placed so that a
// file which cannot reach the loop BODY stays comparable — an ambient file with no
// top-level statement has nothing to require a `declare` modifier of — and this
// fixture is what makes that placement measurable rather than asserted.
