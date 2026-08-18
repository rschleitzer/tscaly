// The dynamic import CALL. `import` is not a node kind of its own here: the
// keyword alone becomes an ImportKeyword node and parseCallExpressionRest builds
// the CallExpression over it, so `import("m")` is a call whose callee is a
// keyword. The file's own flags carry PossiblyContainsDynamicImport, which is
// the SourceFile bit that kept this construct unported for seventeen slices.
const a = import("m");
import("m").then(x => x);
