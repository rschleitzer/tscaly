// Slice 116, and it is the fixture STAGE 2 asked for. An enum member whose name
// is not an identifier prints as an INDEXED ACCESS over a type query, and the
// string literal in it is built with no emit flags — so unlike the string
// literal TYPE one arm up, its non-ASCII characters ARE escaped.
//
// ★★★ THE ARM THAT ANSWERS THIS WAS DELETED IN SLICE 115 WITH A CORRECT REASON.
// escapeStringWorker's supplementary-plane branch and its `ch > 0x7f` disjunct
// were both unreachable while every caller carried NeverAsciiEscape; this slice
// added the caller that does not, and one unit of 18 391 said so
// (`submodule_compiler_enumWithUnicodeEscape1`). Nothing at stage 1 could: no
// fixture in the corpus had a non-ASCII enum member name. §3.5p, measured.
enum E {
  'gold ✰',
  'a b' = 2,
  '\u{1F600}' = 3
}
declare let a: E;
