// The DisallowInContext clear around an ARRAY pattern's element list, which
// slice 9 made reachable: a for initializer is the ONE place in the language
// that SETS the flag, and both binding patterns clear it around their elements.
//
// ★ ONE LINE, and nothing that can go unported, because the claim is a FLAG
// DIFFERENCE and the runner's UNPORTED verdict is per-FILE: it is decided before
// any comparison happens, so a single unported line anywhere in a file hides
// every diff in it. The `in`-operator half of this claim therefore lives in
// parser_binding_arr_in_operator.ts, where dropping the clear costs a matched
// case instead of showing a diff. This is the CONVERSE of the
// parser_types_linebreak technique: an unported case can still gate a claim
// about whether we DECLARE unported, and can never gate a claim about the tree.
for (var [a = 1] = x;;) ;
