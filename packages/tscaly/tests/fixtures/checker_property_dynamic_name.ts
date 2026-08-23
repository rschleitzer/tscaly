// Slice 62. The one term of checkGrammarProperty this port cannot answer, and the
// fixture is a PIN on a TAG rather than on a diagnostic.
//
// ★★★ `isNonBindableDynamicName` IS `IsDynamicName && !isLateBindableName`, and the
// right conjunct resolves the computed name's EXPRESSION — checkComputedPropertyName
// for a `[…]` name — so it is the type dimension one call deep inside a function
// whose other five reports are purely syntactic. The unit's tag is
// `is-late-bindable-name` at KindComputedPropertyName, and that is the whole gate.
//
// ★★★ THE `&&` SHORT-CIRCUITS, WHICH IS WHY THE HOLE IS THIS NARROW: a name that is
// a plain identifier, a string, a number, or a computed name over a LITERAL answers
// false at the LEFT conjunct and asks nothing. Only `[expr]` with a non-literal expr
// gets here, and the binder already decides that half (`b.is_dynamic_name`).
//
// ★★ THE TWO DECLARATIONS ARE THE TWO SIDES OF THE HOLE. For `[k]` the reference
// reports NOTHING — it resolves the name and builds `{ [x: string]: string }` — so
// our tag marks a unit the reference measures cleanly, which is the honest direction.
// For `[1, 2]` the reference DOES report (TS1170) and this port reports nothing,
// because `check_grammar_for_invalid_dynamic_name` answers **true**: every caller
// reads a true as *I have reported* and stops, so a true costs diagnostics while a
// false would invent them, and diagcheck's relation is a SUBSEQUENCE.
//
// ★★ IT IS ALSO WHY checkGrammarComputedPropertyName's REPORT IS UNREACHABLE FROM
// EITHER ARM THIS SLICE PORTS, and the reason is the REFERENCE'S OWN ORDER rather
// than this corpus: a comma expression is never a literal, so the dynamic-name check
// fires in front of it for every property and for every method of a class, an
// interface or a type literal. The report has four callers and the other two are the
// ones that reach it — checkGrammarObjectLiteralExpression, which asks it of every
// object-literal property, and checkAccessorDeclaration, whose own grammar check does
// NOT ask the dynamic-name question first. The accessor pair is this slice's named
// successor, so the report becomes measurable one slice along.
export {};
declare const a: { [k]: string };
declare const b: { [1, 2]: string };
declare const k: string;
