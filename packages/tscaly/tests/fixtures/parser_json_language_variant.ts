// Slice 19 — ★ the surprise of the slice: getLanguageVariant answers JSX for
// ScriptKindJSON, so a .json file is SCANNED under the JSX language variant, and
// `</` is one token there (KindLessThanSlashToken) instead of two.
//
// Four units, because the claim is a conjunction and each clause needs its own
// input:
//
//   variant.json  the JSX reading — one token
//   variant.ts    the SAME BYTES as TypeScript: two tokens and a different tree,
//                 which is what makes the .json reading a measurement rather
//                 than a coincidence
//   star.json     `</*` is NOT a closing-tag token even under the variant — the
//                 reference's third clause, which keeps a comment a comment
//   variant.js    the CLAMP's order: upstream's table answers JSX for .js too,
//                 and this port parses .js as TypeScript, so the variant must be
//                 derived from the CLAMPED kind or the two yardsticks would scan
//                 one file two ways
// @Filename: variant.json
{"a": 1}</
// @Filename: variant.ts
{"a": 1}</
// @Filename: star.json
{"a": 1}</*x*/
// @Filename: variant.js
{"a": 1}</
