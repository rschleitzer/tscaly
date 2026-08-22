// Slice 49. TS1044 — `{0} modifier cannot appear on a module or namespace
// element` — which the visibility arm and the `static` arm both reach by asking
// the PARENT's kind.
//
// ★★ AT THE TOP LEVEL OF A FILE THE PARENT IS ALWAYS A SourceFile, so this unit
// is the SourceFile half of the test. The ModuleBlock half had no fixture when
// slice 49 wrote this — a statement inside a namespace body is reached through
// checkModuleDeclaration -> checkSourceElement(body) -> checkBlock, and neither
// arm was ported — and slice 50 ported both: checker_namespace_element_modifier.ts
// is that half. Kept as two units rather than merged, because the two answers come
// from the same line of check_grammar_modifiers reading a different parent.
public var a: number;
static type T = number;
