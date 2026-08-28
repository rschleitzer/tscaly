// An annotated function's `return`: getReturnTypeFromAnnotation answers, so the
// walk reaches checkReturnExpression and stops there. Its unannotated sibling
// stops one call EARLIER, inside getReturnTypeOfSignature — a body with no
// annotation is what getReturnTypeFromBody serves, and that is the common case.
function annotated(): number {
    return 1;
}
function unannotated() {
    return 1;
}
