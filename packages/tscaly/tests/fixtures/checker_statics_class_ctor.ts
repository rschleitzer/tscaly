// SLICE 87. A DECLARED constructor, so getDefaultConstructSignatures is never
// called: getSignaturesOfSymbol answers the `%FEconstructor` entry's own signature
// and the length test above the default takes the other branch. `G 4 0 2 1` — two
// parameters, one of them optional.
class C {
    constructor(x: string, y?: number) {}
}
