// slice 39 — the class the property lands in is read off the TREE
// (`node.Parent.Parent`) and not off the container register, so a class
// EXPRESSION works exactly as a declaration does — including the anonymous one,
// whose symbol is the internal `class` name that bindAnonymousDeclaration made.
const C = class {
    constructor(readonly x: number) {}
};
const D = class Named {
    constructor(private y: number) {}
};
export const E = class {
    constructor(protected z: number, w: number) {}
};
