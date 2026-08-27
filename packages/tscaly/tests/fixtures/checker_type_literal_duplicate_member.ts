// SLICE 80: checkObjectTypeForDuplicateDeclarations reached through a TYPE
// LITERAL. The function was ported in slice 73 for the class and has had a `false`
// call site with no input ever since — this is that input.
declare const twoProperties: { p: string; p: number };
