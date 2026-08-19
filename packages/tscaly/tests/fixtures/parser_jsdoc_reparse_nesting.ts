// Slice 22 — WHERE a synthesized declaration lands. parseListIndex flushes the
// reparse list into the list being parsed, except that a JS type alias or a JS
// import produced inside a list that cannot hold a declaration is propagated
// OUTWARDS to the nearest one that can.
//
//   in a block      -> stays in the block (PCBlockStatements holds declarations)
//   in a class body -> propagates out to the source elements
//
// @Filename: nest.js
function f() {
    /** @typedef {string} Inner */
    var x = 1;
    return x;
}

class K {
    /** @typedef {number} FromClass */
    m() {}
}
