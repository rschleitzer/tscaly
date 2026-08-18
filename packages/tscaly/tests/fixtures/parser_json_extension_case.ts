// Slice 19 — GetScriptKindFromFileName lowercases the extension before it
// switches, so an upper-case name selects the JSON grammar too. Both halves are
// visible in one unit: the 1327 proves the JSON validator ran, and the `</`
// proves the language variant came with it.
// @Filename: Upper.JSON
{a: 1}</
