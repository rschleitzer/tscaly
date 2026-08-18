// Neither `with` nor `assert`, which is the arm that made a pre-existing
// deviation reachable: the reference does NOT advance past the offending word,
// so parseImportAttributes is entered with no `{` left to read and hands the
// node the MISSING-LIST sentinel — an empty ImportAttributes at pos = end, with
// `oops: 1` read afterwards as a LABELED STATEMENT. This port parsed the list
// unconditionally, which was the same tree for every slice-8 caller.
type A = import("m", { oops: 1 });
