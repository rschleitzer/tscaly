// Slice 24 — the import/export arms. Six shapes and three codes: the four
// type-only forms share one, `import =` and `export =` have their own.
//
// ★ The import CLAUSE is asked, not the declaration — `IsTypeOnly` for a clause
// is derived from its PHASE MODIFIER, because `import type A`, `import defer A`
// and a plain import are one node kind under three words.
// @Filename: import_export.js
import type A from "m";
import { type b } from "m";
export type { c } from "m";
export { type d };
import E = require("m");
export = E;
