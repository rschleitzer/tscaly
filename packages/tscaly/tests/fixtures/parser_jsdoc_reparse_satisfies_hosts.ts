// Slice 22 — @satisfies, whose hosted switch is a DIFFERENT list from @type's
// and wraps the INITIALIZER in a satisfies-expression rather than annotating a
// type slot. Nine arms; the corpus reaches four of them.
// @Filename: sat.js
/** @satisfies {string} */
var a = "x";

/** @satisfies {number} */
let b = 1, c = 2;

class K {
    /** @satisfies {string} */
    p = "x";
}

const y = 1;
const o = {
    /** @satisfies {string} */
    k: "x",
    /** @satisfies {number} */
    y,
};

function f() {
    /** @satisfies {string} */
    return "x";
}

/** @satisfies {string} */
export default "d";

module.exports.z = /** @satisfies {number} */ 1;
