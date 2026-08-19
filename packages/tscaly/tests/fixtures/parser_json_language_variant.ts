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
//   variant.js    ★ slice 22 turned this unit from a claim about the CLAMP into
//                 a measurement of the variant itself. It was written to say
//                 that the variant must be derived from the CLAMPED kind, since
//                 .js was parsed as TypeScript and upstream's table answers JSX
//                 for .js; there is no clamp any more and a .js unit is scanned
//                 JSX on both sides. What the unit now pins is bigger: it is one
//                 of only TWO units in the whole comparison whose TREE the
//                 variant moves — `{"a": 1}</` reads as SEVEN nodes under JSX
//                 and TWELVE under Standard. A fixture written to ask about a
//                 workaround outlived the workaround and started measuring the
//                 thing itself.
// @Filename: variant.json
{"a": 1}</
// @Filename: variant.ts
{"a": 1}</
// @Filename: star.json
{"a": 1}</*x*/
// @Filename: variant.js
{"a": 1}</
