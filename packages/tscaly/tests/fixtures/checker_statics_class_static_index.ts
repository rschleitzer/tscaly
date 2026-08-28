// SLICE 87. The index-symbol branch, and the only one of the four whose product a
// SECOND instrument can see: a STATIC index signature is filed in the EXPORTS
// table under `%FEindex`, so getIndexInfosOfIndexSymbol runs on the static side and
// `check-index-constraint` appears in the stop log one call further on.
class C {
    static [k: string]: string;
}
