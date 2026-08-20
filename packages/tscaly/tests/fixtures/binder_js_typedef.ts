// A JavaScript `@typedef` becomes a JSTypeAliasDeclaration statement, and WHERE it
// sits decides which half of slice 30 binds it: a TOP-LEVEL one is deferred to the
// tail of bindContainer so that the CommonJS module indicators are known first,
// while one inside a function body is bound by bind()'s own arm. Neither half
// alone is enough, and a typedef bound by neither declares nothing at all.
// @Filename: typedefs.js
/** @typedef {string} Outer */
function f() {
    /** @typedef {number} Inner */
    return 1;
}
