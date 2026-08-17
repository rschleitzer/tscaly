type A = {};
type B = { a: string };
type C = { a: { b: { c: number } } };
type D = { a: string }[];
type E = { a: string } | { b: number };
type F = () => { a: string };
let g: { a: number };
function h(p: { a: string }): { b: number } { return p as any; }
