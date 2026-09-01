// Slice 115's anyArrayType — a rest parameter with no annotation, whose type is
// `createArrayType(anyType)`. Both of the reference's two eager createArrayType
// calls used to be a stop here naming the missing global; this is the one whose
// path has no other wall in front of it.
function f(...r) { }
