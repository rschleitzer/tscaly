// Slice 100: the four walls this chapter leaves standing, each with the shape
// that reaches it. A file of stops rather than of answers, so that a control
// removing one of them moves a TAG rather than a diagnostic.
export {}

// getEffectiveCallArguments — the IIFE branch of getContextuallyTypedParameter
// Type, which types a parameter off the ARGUMENT at its position.
const iife = (function (x) { return x })(1)

// getReturnTypeFromBody — reached when a contextual signature exists, the
// function has no return annotation, and the signature's return type has not
// been resolved.
type Ret = () => number
const fromBody: Ret = function () { return 1 }

// ★★ compareSignaturesIdentical — a contextual type that is a UNION two of whose
// members are callable. Written INLINE rather than through a type alias for the
// reason fnexpr_contextual.ts's header gives: an alias reaches
// get-type-from-type-alias-reference one chapter out and the group never gets
// here.
const uniontarget: ((x: number) => number) | ((x: string) => string) = (x) => x

// ★★ getIntersectedSignatures — a contextual type with TWO call signatures, so
// the applicable set is not of size one and the fold behind it is reached.
// noImplicitAny is true under this harness, so its first line does not answer.
const overloadtarget: { (x: number): number; (x: string): string } = (x) => x

// getInferenceContext — a context-sensitive function under a contextual
// signature, which is the inference dimension.
const inferctx: (x: number) => number = (x) => x
