// Slice 61. checkTypeLiteral's members walk — the line whose yield is not its own
// arm's but everybody else's.
//
// ★★★ TWO OF THE FIVE MEMBER KINDS WERE ALREADY PORTED AND UNREACHED. An index
// signature's checkGrammarIndexSignature report has stood since slice 52, whose
// comment reads *no arm of this slice can reach it (an index signature is a class
// or interface MEMBER, and neither container's members are walked yet)*; a call
// signature's whole checkSignatureDeclaration is slice 52's own function. Both are
// live from here, and the second brings slice 60's duplicate-type-parameter report
// with it — TS2300 below comes out of a construct signature nested in a type
// literal, three ported functions deep.
//
// ★ A property signature and a method signature have no arm yet and report their
// own kind, which is what makes `check PropertySignature` a row of the histogram
// for the first time.
export {};
declare const emptyTypeParameterList: { <>(): void };
declare const duplicateTypeParameters: { new <T, T>(): void };
declare const propertySignature: { p: string };
