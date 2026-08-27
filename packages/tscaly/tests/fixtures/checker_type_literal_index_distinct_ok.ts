// SLICE 80: the negative control of checker_type_literal_duplicate_index — the
// grouping is by the parameter's TYPE and not by the declaration COUNT, so a
// string index beside a number index is two declarations of one index symbol and
// must produce nothing.
declare const stringAndNumberIndex: { [k: string]: any; [j: number]: any };
