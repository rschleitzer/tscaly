// `import.meta` — a MetaProperty built from the import keyword. Both tokens are
// consumed directly rather than through parseExpected, and whatever follows the
// dot is read as an identifier NAME, so the parser never checks the word.
// The file carries PossiblyContainsImportMeta, a different bit from the call's.
const a = import.meta;
const b = import.meta.url;
