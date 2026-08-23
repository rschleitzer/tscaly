// Slice 57. checkTypeNameIsReserved through the TYPE ALIAS arm — TS2457. The
// same eleven spellings, a different message, and the code is therefore a
// PARAMETER of check_type_name_is_reserved rather than a constant in it: six
// call sites in the reference pass six different messages for one list.
//
// ★★★ LINE 3 IS THE REFERENCE SAYING SOMETHING WE DO NOT, AND IT IS CORRECT
// EITHER WAY. `type Object = number` is TS2300 — a duplicate identifier — while
// `interface Object {}` in the neighbouring fixture is silent, because an
// interface MERGES with the global declaration and an alias does not. Neither
// line is checkTypeNameIsReserved's: `Object` is not one of the eleven. So this
// unit is where diagcheck's SUBSEQUENCE relation is doing real work — our three
// lines sit inside the reference's four, and a subset test would have accepted
// them in any order.
//
// ★ `Thing` is the clean negative, as in the interface fixture.
type string = number;
type undefined = number;
type Object = number;
type Thing = number;
