// propertyRelatedTo's last rule, from the other side: an OPTIONAL source property
// against a REQUIRED target class member is refused. ★The class is what makes it
// fire — the rule asks SymbolFlagsClassMember on the target property, so the same
// pair spelled as two object types is silent.
//
// ★★★ THIS FILE FOUND THE SLICE'S SHARPEST DEFECT AND NO CORPUS UNIT COULD: with
// the error node forwarded into the nested relation, ONE assignment reported
// TS2322 THREE TIMES — once per failing LEVEL — because the reference appends to
// a chain that is emitted once and this port emits at the line. diagcheck is a
// SUBSEQUENCE and refuses extras, and it was GREEN over all 1 635 corpus units:
// nothing out there reaches a nested failing relation through an error node.
class C { a: number = 1; }
declare let s: { a?: number };
declare let t: C;
t = s;
