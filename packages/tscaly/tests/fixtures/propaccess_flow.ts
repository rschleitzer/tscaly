// Slice 96 — getFlowTypeOfAccessExpression, whose SECOND test is where most
// answers leave: a property whose symbol is a METHOD, a function or an enum
// member is not narrowable, so `return propType` is the whole function for it.
// What reaches the flow walk is a variable, a property or an accessor.
//
// ★ THE THREE SHAPES BELOW ARE THE THREE OUTCOMES, and two of them are walls this
// slice PRICES rather than closes. A plain property runs the walk to its answer;
// a UNION-typed property reaches the narrowing and stops there (`narrow-type`);
// an ACCESSOR stops one call earlier still, in getTypeOfAccessors. Naming which
// of the three a shape takes is what the PROPPIN is for — the first leaves a row
// and the other two do not.
export {}

interface Plain { v: number }

function readPlain(p: Plain): number {
    return p.v
}

interface Narrowable { v: string | undefined }

function narrowed(n: Narrowable) {
    if (n.v) {
        return n.v
    }
    return ""
}

class Accessors {
    private backing: number = 0
    get value(): number { return this.backing }
}

function readAccessor(a: Accessors): number {
    return a.value
}
