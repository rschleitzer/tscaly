// SLICE 85. The `%FEcall` member — getSignaturesOfSymbol's one input in this
// slice. The parameter's annotation is a TypeReference, so building the signature
// walks into getTypeFromTypeNode and stops there; before this slice nothing asked
// for the signature at all, so that stop is the slice arriving.
interface Arg {
    a: string;
}
declare const callable: { (x: Arg): string };
