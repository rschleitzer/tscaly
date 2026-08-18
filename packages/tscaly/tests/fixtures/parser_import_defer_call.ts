// `import.defer(…)` is a DYNAMIC IMPORT, not an `import.meta` — the same node
// with a different file flag, decided by the WORD and by a `(` or `<` following
// it. This is the one shape the pinned corpus reaches (importDeferCallCommonJS),
// and it is why the identifier TEXT slice 17 stored is load-bearing here: the
// name went through parseIdentifierName, so the contextual-keyword KIND that
// answers the same question in an import DECLARATION was already spent.
import.defer("m");
const a = import.defer<string>("m");
