// The other side of the same test: `defer` with no call after it takes the
// import.meta branch, so the file is marked PossiblyContainsImportMeta even
// though nothing here is `import.meta`. The flag says POSSIBLY, and the walk
// that reads it asks the precise question.
const a = import.defer;
