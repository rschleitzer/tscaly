// Slice 54. checkGrammarNameInLetOrConstDeclarations, both halves.
//
// ★★ THE FUNCTION ALWAYS ANSWERS FALSE FOR A PATTERN AND THE RECURSION'S RESULT
// IS DISCARDED, which is the opposite discipline to the `__esModule` walk four
// lines away in the reference — that one RETURNS out of its loop on the first
// element with a name. The two are deliberately not unified.
//
// ★ The second line is the negative: a binding element's NAME is `z`, so the
// property name `let` is never asked about. `let` is a legal property name and an
// illegal binding name, and only the name side is checked.
let let = 1;
const { let: z } = { let: 1 };
