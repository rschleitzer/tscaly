// @callback, whose signature ends by SPECULATING on one more tag: if the tag
// after the parameters is a @return it becomes the signature's type, and if it
// is anything else the speculation is rewound and the tag belongs to the comment.

/**
 * @callback Cb
 * @param {number} a
 * @param {string} b
 * @deprecated not a return tag
 */
var c;

/**
 * @callback Cb2
 * @param {number} a
 * @returns {boolean}
 */
var d;
