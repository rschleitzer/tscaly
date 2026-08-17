// `for (let of X)` — the user meant `of` as the keyword, and `of` is a legal
// identifier, so only a look-ahead tells them apart. The reference answers
// with an EMPTY declaration list (createMissingList) that still spans `let`
// and still carries NodeFlagsLet, after which `of` is the keyword.
for (let of X) { }
