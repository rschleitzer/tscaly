// Slice 50. TS1063 and TS1319 — the two reports of checkExportAssignment's
// CONTAINER WALK, and the only path of that arm which RETURNS rather than ending
// in a report about something unported.
//
// ★★★ IT IS ALSO THE FIXTURE THAT PROVES THE BLOCK ARM IS LOAD-BEARING. An
// export assignment inside a namespace is reached only through
// checkModuleDeclaration -> checkSourceElement(body) -> checkBlock, which is the
// second half of this slice; with that arm absent neither line here is reachable
// at all, and slice 49 said so in as many words. The walk itself is what picks the
// message: the parent is a ModuleBlock, so the container steps up to the
// ModuleDeclaration, and a non-ambient one is the error.
//
// ★ `export =` and `export default` are ONE node kind under a field, which is why
// both spellings are here: the two reports differ only by that field's value, so a
// fixture with one of them cannot tell a swapped pair from a correct one.
namespace N { export = 1; }
namespace M { export default 1; }
