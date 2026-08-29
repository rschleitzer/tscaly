// The reduction steps that CAN fire here, exercised through the ANNOTATION path
// (checkUnionOrIntersectionType -> getTypeFromUnionTypeNode): `never` is ignored
// by addTypeToUnion, `any` and `unknown` swallow the whole union in
// getUnionTypeWorker, a duplicate constituent is dropped by the sorted insert, and
// two spellings of one union intern to ONE type. The `undefined` lines are also
// the PRINTER's half: undefined sorts to the FRONT (1 << 2, ahead of string's
// 1 << 5) and formatUnionTypes moves it to the END, which is the only place the
// stored order and the printed one differ.
//
// ★★ THERE IS NO `| null` LINE HERE AND THAT IS A CONTAINMENT PROOF RATHER THAN AN
// OMISSION: `null` in a TYPE position is a KindLiteralType node, which
// getTypeFromTypeNode reports for, so the null half of formatUnionTypes has no
// input in this port at all. Three such lines were written and removed again —
// they contribute a stop and no union.
//
// ★ The assertion is the ABSENCE of a stop: none of these lines may report
// `get-type-from-type-node 193` any more. The T section cannot show the answers —
// a VariableStatement has no ported arm in getTypeOfNode, which is the type-walk
// chapter and not this one.
declare let a: string | never;
declare let b: string | any;
declare let c: string | unknown;
declare let d: string | string;
declare let e: string | number;
declare let f: number | string;
declare let g: undefined | string;
declare let h: string | undefined | number;
declare let i: boolean | undefined;
declare let j: string | void;
declare let k: string | number | boolean | undefined;
