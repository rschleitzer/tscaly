// Slice 117 — the INDEX SIGNATURE path of getPropertyTypeForIndexType, which is
// the arm that runs when getPropertyOfType finds nothing.
//
// ★★★ AND IT MEASURES NOTHING TODAY, WHICH IS THE POINT OF KEEPING IT. Every one of
// the three controls aimed at this arm came back UNGATED, and the reason is not the
// arm: `check-grammar-index-signature` stops the walk at the FIRST node of any file
// that contains an index signature (52 units of the stage-2 corpus), so no source
// this port can check ever reaches an index signature's value type. The fixture is
// the marker for that wall — the day the grammar check lands, three rows of
// tests/controls-slice117.sh go red without being rewritten.
//
// ★ What the arm would answer: `sig` has no declared `a`, so the string index
// signature answers and both bindings are `number`; `arr` exercises the other
// applicable-index rule, a numeric name against a NUMBER index signature.
declare const sig: { [k: string]: number };
const { a, b } = sig;
declare const arr: { [k: number]: string };
const { 0: first } = arr;
