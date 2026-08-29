// checkAllCodePathsInNonVoidFunctionReturnOrThrow, which needs nothing of the
// flow walk but its REACHABILITY half. Four shapes: an annotated function whose
// end point is reachable and which never returns a value, one that returns on
// every path (no report at all), a `never` return type with a reachable end
// point, and an arrow with an expression body (nothing to check).
declare function guard(): boolean;
function noReturn(): string {
}
function allPathsReturn(q: boolean): string {
    if (q) {
        return "a";
    }
    return "b";
}
function neverEnds(): never {
}
const expr = (): string => "x";
