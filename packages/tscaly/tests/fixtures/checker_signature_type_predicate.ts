// checkTypePredicate past its first report: the signature is built and the stop
// moves one call along, to getTypePredicateOfSignature.
function isString(x: unknown): x is string {
    return true;
}
