// Slice 22 — @import, the tag that becomes a JSImportDeclaration. Its clause is
// cloned and then MUTATED — the phase modifier becomes `type` — which is the
// only write this port makes to a clone, and therefore the one place §3.5bf's
// shared-children shortcut is load-bearing rather than free.
// @Filename: imp.js
/** @import { A } from "mod" */

/** @import D, { B as C } from "mod" with { type: "json" } */

/** @import * as NS from "mod" */
