// SLICE 82: the THIRD term of the reference's second guard — `NodeIsMissing(fn.
// Body())` — and the only shape that can reach it with a type in hand. An overload
// signature with a return annotation is not void, is not a MethodSignature, and has
// no body, so it leaves the chapter one term before the flow graph.
//
// ★ It carries no TS7010 and that is the point of pairing it with
// checker_return_path_overload_implicit_any: the implicit-any block's guard is
// `node.Type() == nil`, so an ANNOTATED overload is silent on both sides.
function annotatedOverload(x: number): number;
function annotatedOverload(x: any) { return x; }
