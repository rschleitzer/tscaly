// A parameter documented by a TRAILING comment. GetJSDocCommentRanges consults
// the trailing comments of a node's position for seven kinds and only for those
// seven — a Parameter is one, a FunctionDeclaration is not — so this is the one
// shape in which the trailing branch decides anything.

function f(/** the first */ a, /** the second */ b) { return a; }

var g = function (/** @type {number} */ c) { return c; };

var h = (/** the only one */ d) => d;
