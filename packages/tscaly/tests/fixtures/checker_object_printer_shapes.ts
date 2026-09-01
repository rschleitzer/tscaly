// Slice 111. The shapes an ANONYMOUS OBJECT TYPE has a name for, in one unit: the
// function type, the constructor type and the type literal — plus the two the PRINTER
// decides rather than the builder, the empty `{}` and a member ORDER that is the
// reference's (call signatures, then construct signatures, then properties) and not
// the source's. ★The INDEX signature is absent on purpose: `check-grammar-index-signature`
// stops this unit before its dump, so a row for it would measure that chapter.
declare const fn: (a: string, b?: number) => void;
declare const thisp: (this: string, a: number) => void;
declare const ctor: new (x: number) => string;
declare const empty: {};
declare const lit: { p: string; q: number };
declare const mixed: { x: number; (a: string): void; new (b: number): string };
declare const meth: { m(p: number): void };
declare const ro: { readonly r: string };
declare const nested: (p: { q: string }) => { r: number };
