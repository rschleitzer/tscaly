// TS7051 — a signature parameter whose NAME reads as a type. Both disjuncts of
// reportImplicitAny's test are here on purpose: `string` is decided by the
// keyword table (IdentifierToKeywordKind + IsTypeNodeKind) and `Array` only by
// resolveName against the globals the lib declares, which is the half the row
// waited on from slice 79 to slice 149.
//
// Two negative controls, and they fail the test in DIFFERENT places. `notAType`
// passes the parent test and both disjuncts miss, so it falls through to TS7006
// — a resolver answering too generously shows up here rather than as a missing
// line. The class method fails the PARENT test instead: a MethodDeclaration is
// not a MethodSignature, so `string` there is TS7006 as well, and the two 7006
// lines together pin the arm from both sides.
interface I { (Array): void }
interface J { (string): void }
interface K { (notAType): void }
type F = (Array) => void;
declare class C { m(string): void }
