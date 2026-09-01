// Slice 114: isErrorType's SECOND disjunct. An `any` that carries an alias is the
// one getTypeFromTypeAliasReference manufactures for an unresolved name, and the
// reference wants it to BEHAVE like errorType at all 49 sites that ask.
//
// ★ The witness is the property access: its isAnyLike branch answers the
// apparent type unless the predicate says error, so without the disjunct `x.id`
// came out as `Request` — a well-formed wrong answer — instead of `any`.
import { Request } from "express";
let x: Request;
const y = x.id;
