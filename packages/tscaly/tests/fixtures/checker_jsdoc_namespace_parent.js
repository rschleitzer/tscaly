// Slice 50, and the FIRST .js fixture in this package — see run.sh's collector for
// why there was none and why that mattered.
//
// ★★★ IT IS THE GATE FOR A PARSER DEFECT NO EARLIER YARDSTICK COULD SEE.
// `@typedef {T} A.B.MyType` is reparsed into nested ModuleDeclarations, and
// finish_reparsed_node did not call override_parent_in_immediate_children the way
// the reference's finishReparsedNode does — so the inner declaration kept the
// JSDoc node it was parsed under as its parent. `parent` is in no dump: not the
// token stream, not the tree walk (depth, kind, pos, end, flags), not a symbol. So
// four yardsticks compared equal and the fifth INVENTED a diagnostic:
// checkGrammarModuleElementContext asked the inner module for its parent's kind,
// got neither SourceFile nor ModuleBlock nor ModuleDeclaration, and reported a
// TS1235 the reference does not.
//
// ★★ ITS EXPECTED ANSWER IS THE EMPTY C SECTION, and that is exactly what
// diagcheck is able to fail on: a line we invent. Restore the missing call site
// and this unit prints `C 31 32 1235` — the span of the `B`, inside a comment,
// which is the shape a wrong parent produces.
/** @typedef {{age: number}} A.B.MyType */
