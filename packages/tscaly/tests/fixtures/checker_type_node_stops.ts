// Slice 61. The arms whose whole body is a stop, and the arms whose recursion is
// free — walked in one unit so that the chapter's silent half is exercised rather
// than assumed.
//
// ★★ A UNIT CARRIES ONE TAG (record_unported keeps the FIRST), so this fixture
// pins the TypeQuery stop and no more; the three other stops it walks over —
// IndexedAccessType, MappedType and TemplateLiteralType — are reached by the
// corpus at stage 2 and appear in the histogram there. What this
// fixture gates is the other half of the claim: none of these arms invents a
// diagnostic, and the reference's C section for this unit is EMPTY.
//
// ★ TWO KINDS ARE DELIBERATELY NOT IN THE LIST, both because they cost the unit
// its empty C section: a `this` type outside a class body is TS2526, and an
// `import("m")` is TS2307 — the oracle's program is a stub over the lib set plus
// the unit, so no specifier resolves. Their arms are walked by the corpus at
// stage 2 instead.
export {};
declare const q: typeof globalThis;
declare const i: [string, number][0];
declare const m: { [K in "a"]: number };
declare const l: `x${string}y`;
declare const c: string | number & boolean;
