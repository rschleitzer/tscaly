// ★★★ THE MODULE INDICATOR'S LAST ARM. This file has no export, no import
// declaration and no export assignment — it is a module SOLELY because
// `import.meta` occurs in it, which the reference finds by walking the tree
// under the PossiblyContainsImportMeta flag (getImportMetaIfNecessary). And
// because it is a module, the second statement is RE-PARSED with AwaitContext
// on: `await` is an AwaitExpression here and an identifier in the twin file.
const u = import.meta.url;
const a = await;
