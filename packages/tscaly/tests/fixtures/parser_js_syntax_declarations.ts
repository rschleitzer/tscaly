// Slice 24 — the four declaration kinds reported at their NAME rather than at
// the whole node, plus the two spellings of a module. All four share one code
// except the type alias, which has its own.
// @Filename: declarations.js
interface I {}

enum E {}

namespace N {}

module M {}

type T = number;
