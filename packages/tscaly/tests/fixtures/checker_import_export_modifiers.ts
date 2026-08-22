// Slice 50. The three `cannot have modifiers` reports of the import/export
// family, plus the checkGrammarModifiers arm that goes live with it — four codes
// in one unit, and the unit is what shows they come out in POSITION order rather
// than in discovery order.
//
// TS1079  `declare` on an import declaration      — checkGrammarModifiers' own
//         import arm, ported in slice 49 and unreachable until this one
// TS1191  an import declaration cannot have modifiers
// TS1193  an export declaration cannot have modifiers
// TS1120  an export assignment cannot have modifiers
//
// ★★ THE THREE TS11xx REPORTS ARE ABOUT A LEGAL MODIFIER IN AN ILLEGAL PLACE, not
// about a malformed one — every one of these kinds is on CanHaveIllegalModifiers,
// so reportObviousModifierErrors passes them through and checkGrammarModifiers
// finds nothing to say. That is why the condition is `!checkGrammarModifiers(node)
// && node.Modifiers() != nil`: the report fires exactly when the modifier is
// well-formed and the statement may not carry it.
//
// ★ The reference also answers TS2307 on three of these lines (`cannot find
// module`) and a TS2714; both need the module resolver and the expression checker,
// so our lines are a strict SUBSET here — which is the relation diagcheck asserts
// and the reason it is a subsequence test.
declare import a from "./a";
export import b from "./b";
declare export {};
declare export = 1;
