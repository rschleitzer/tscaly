// slice 43 — the null container, i.e. the SECOND rule of the arm.
//
// An `infer` that is nowhere in an extends clause parses (it is a CHECKER error,
// not a syntactic one), getInferTypeContainer answers nothing, and the type
// parameter takes bindAnonymousDeclaration instead: a symbol with the name
// getDeclarationName gives it, a declaration, and NO table.
//
// ★★ Two things separate the arms in this dump and either one catches a port that
// used the declaring arm for both. The symbol is in no table — so `U`, `V` and `W`
// appear as `s` lines that no `e` line names — and the file's CLASSIFIABLE names do
// not learn them, although a type parameter IS classifiable, because that list is
// written by declareSymbolEx and the anonymous path does not go through it.
//
// ★ And a third, from the other direction: the two aliases that hold nothing but an
// infer have no LOCALS TABLE AT ALL. A port that asked for the enclosing
// container's locals before testing for null would mint an empty one, and an empty
// table is visible here as an extra node line and an extra `t 0`.
type Bare = infer U;
type InCheck = infer V extends string ? 1 : 2;
type InTrue<T> = T extends string ? infer W : never;
