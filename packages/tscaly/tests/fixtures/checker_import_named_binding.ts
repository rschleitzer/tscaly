// Slice 59. `import { a } from "m"` — the NAMED arm, which does not reach
// checkImportBinding at all.
//
// ★★★ THE RESOLVER GATES THE LOOP: `resolvedModule = resolveExternalModuleName(...)`
// and the specifiers are visited only `if resolvedModule != nil`. Under this
// harness nothing resolves — the stub program answers no module — so on the
// reference side the loop never runs either, and the tag names the resolver
// rather than the binding. That is why this shape is a row of its own and not a
// third caller of the head.
import { a } from "./a";
