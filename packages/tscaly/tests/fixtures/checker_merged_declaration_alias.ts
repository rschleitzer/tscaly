// Slice 65. The one HOLE inside getDeclarationSpaces, reached — and it is a PIN
// fixture, because a hole produces no diagnostic by construction.
//
// ★★★ THE ALIAS ARM NEEDS A MERGE WHOSE DECLARATIONS ARE NOT ALL THE SAME KIND, and
// getting there took four attempts worth recording. An `import fs = require("fs")`
// beside a namespace is not enough: checkModuleDeclaration walks the namespace BODY
// first, so `export var x = 1` inside it reports before the merged-declaration check
// is reached, and the import declaration's own arm reports earlier still. What works
// is an EXPORTED namespace with an EMPTY body — exported so the local symbol exists
// and the head does not return, empty so nothing inside it speaks first.
//
// ★★ WHAT THE ARM WOULD DO IS OR TOGETHER THE SPACES OF EVERYTHING THE ALIAS TARGET
// DECLARES, which is `c.resolveAlias`, i.e. the whole of getTargetOfAliasDeclaration
// — the `check-alias-symbol` row of the work list. Answering DeclarationSpacesNone
// instead would be §3.5bk's silent wrong answer: no space means no intersection
// means no report, and the check would go quiet for every merge that includes an
// import.
export {};
export namespace fs { }
import fs = require("fs");
