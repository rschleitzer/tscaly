// Slice 95's DEFERRED reference — isDeferredTypeReferenceNode, the fork that
// decides whether a generic reference is built now or lazily, and the one place
// in this chapter where getting the answer wrong in the FALSE direction is a
// well-formed wrong answer rather than a stop.
//
// ★ Both names below are deferred and for DIFFERENT reasons, which is why there
// are two: `A` because getAliasSymbolForTypeNode names it (the reference IS an
// alias's type, the first disjunct), and `B` because it is inside one — the
// second disjunct, `isResolvedByTypeAlias` plus a type argument that may itself
// resolve to an alias. ★`c` is the control on the same line: it stands in a
// LET annotation, so isResolvedByTypeAlias walks to a VariableDeclaration and
// answers false, and the reference is built eagerly.
declare namespace N {
    interface Box<T> { v: T; }
    type Inner = number;
    type A = Box<string>;
    type B = Box<Inner>;
    let c: Box<string>;
}
