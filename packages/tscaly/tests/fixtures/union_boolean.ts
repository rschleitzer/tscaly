// booleanType is the FIRST union this port mints, and it is the one union that
// does not print as a union: getUnionTypeFromSortedList sets TypeFlagsBoolean on a
// two-boolean-literal pair, and type_to_string's Boolean keyword arm stands far
// above the union arm. It arrives by two routes -- the KEYWORD
// (getTypeFromTypeNode's KindBooleanKeyword) and the WIDENING of a fresh boolean
// literal (getWidenedLiteralType) -- and both stopped before slice 94.
declare let flag: boolean;
declare let maybeFlag: boolean | undefined;
declare function takesBool(b: boolean): boolean;
let inferredTrue = true;
let inferredFalse = false;
const keptTrue = true;
