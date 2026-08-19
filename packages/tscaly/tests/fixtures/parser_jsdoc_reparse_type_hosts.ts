// Slice 22 — @type's HOSTED arms. reparseHosted's KindJSDocTypeTag switch has
// four groups and the corpus does not reach all of them, so each host that is
// its own arm gets one line here:
//
//   VariableStatement            the loop over declarations, first UNTYPED one
//   VariableDeclaration          the direct arm
//   PropertyDeclaration          "
//   PropertyAssignment           "
//   ShorthandPropertyAssignment  "
//   GetAccessor                  "
//   Parameter                    its own arm — the type goes through
//                                reparseJSDocTypeLiteral, not a plain clone
//   ExportAssignment             the direct arm, reached as `export default`
//
// @Filename: hosts.js
/** @type {string} */
var a;

/** @type {number} */
let b = 1, c = 2;

class K {
    /** @type {string} */
    p;

    /** @type {number} */
    get g() { return 1 }

    /** @type {boolean} */
    m(/** @type {{ x: string }} */ q) { return q }
}

const y = 1;
const o = {
    /** @type {string} */
    k: "x",
    /** @type {number} */
    y,
};

/** @type {string} */
export default "d";
