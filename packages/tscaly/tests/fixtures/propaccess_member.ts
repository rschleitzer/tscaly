// Slice 96, and the fixture the chapter opens on: a property access whose
// RECEIVER resolves locally. The file is a MODULE (`export {}`), because a
// script's top-level names are merged into globals upstream and this port has no
// globals table (§3.11) — so `declare const p: Point` at script scope would miss
// on the RECEIVER and measure the table's absence instead of this chapter.
//
// What the PROPPIN reads off it: which member the lookup found (the symbol-flags
// column tells a property from a method), what it looked in (the apparent-type
// column), and what the access answers.
export {}

interface Point { x: number; y: string; m(): number }

function readProperty(p: Point): number {
    return p.x
}

function readOtherProperty(p: Point): string {
    return p.y
}

// A METHOD is a different symbol flag and a different answer from a property of
// the same shape, which is the distinction a name-only pin cannot make.
function readMethod(p: Point) {
    const f = p.m
    return f
}

// Two hops: the second one reads the resolvedSymbol slot the first one wrote.
interface Outer { inner: Point }

function readChain(o: Outer): number {
    return o.inner.x
}

class Holder { value: number = 1 }

function readClassMember(h: Holder): number {
    return h.value
}
