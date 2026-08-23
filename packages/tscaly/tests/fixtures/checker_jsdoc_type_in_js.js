// Slice 61. The other side of checkJSDocTypeIsInJsFile: in a JavaScript file the
// function is a NO-OP, and this fixture is what makes that claim gateable.
//
// ★★★ IT EXISTS BECAUSE A CONTROL CAME BACK UNGATED FOR TWO DIFFERENT REASONS AT
// ONCE. Removing the JS-file guard moves nothing, and the first reason is a gate
// one step earlier — a JSDoc type reaches the tree only through the reparser, hung
// on a declaration that carries NodeFlagsHasJSDoc, and check_source_element_worker
// reports `check-jsdoc-comments` and returns before the switch. Lift THAT gate and
// the row still moves nothing, and the second reason is this one: no unit of the
// corpus puts a `*` or a JSDoc type literal in a type slot our walk reaches. That
// is §3.5v's first row, *uncovered*, and its answer is a fixture rather than an
// argument.
//
// ★★ THE REFERENCE REPORTS NOTHING HERE AND NEITHER DO WE — that is the whole
// point. `@type {*}` is legal JavaScript-with-JSDoc; TS8020 is what a port that
// dropped the guard would invent, and the file is silent in the baseline and loud
// under the control.
/** @type {*} */
var z;
