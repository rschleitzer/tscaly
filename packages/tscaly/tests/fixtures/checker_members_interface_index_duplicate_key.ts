// SLICE 85. findIndexInfo's guard inside get_index_infos_of_index_symbol: two
// declarations of ONE key type contribute ONE index info, and the FIRST wins.
// (checkTypeForDuplicateIndexSignatures reports TS2374 on the pair — that is
// slice 77's report and not this slice's.)
interface I {
    [k: string]: string;
    [j: string]: string;
}
