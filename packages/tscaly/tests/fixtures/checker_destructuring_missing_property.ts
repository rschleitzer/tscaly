// Slice 117 — the REPORT half of getPropertyTypeForIndexType: a name the source
// does not have.
//
// ★ The diagnostic lands on the property NAME, because that is the access node a
// destructuring passes; an element access would report on its argument instead.
declare const src: { a: number };
const { nope } = src;
