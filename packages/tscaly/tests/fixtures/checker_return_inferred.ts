// SLICE 112: getReturnTypeFromBody. A body with no return annotation is what
// getReturnTypeOfSignature's default arm ends in, and it is the common case:
// every function here gets its type from the returns rather than from a type node.
function one() { return 1; }
function none() { }
function bare() { return; }
function branch() { if (1) { return 1; } }
function unreachableEnd() { throw 1; }
function nul() { return null; }
function undef() { return undefined; }
const arrow = () => 1;
const expr = function () { return true; };
