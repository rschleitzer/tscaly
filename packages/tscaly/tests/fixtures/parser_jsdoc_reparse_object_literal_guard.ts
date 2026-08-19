// Slice 22 — the two tags that must NOT fire inside an object literal, because
// its members are not class-like members there and reparsing them would produce
// grammar errors the reference does not (upstream #4437). Both guards read the
// same parsing context, and both are here so that removing either one is red.
// @Filename: guard.js
const o = {
    /** @override */
    m() {},

    /**
     * @overload
     * @param {string} a
     * @returns {void}
     */
    n(a) {},
};

class K {
    /** @override */
    m() {}
}
