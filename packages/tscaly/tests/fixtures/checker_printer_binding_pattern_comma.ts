// Slice 183: a binding pattern printed as a parameter NAME keeps the source's
// trailing comma, because both pattern lists are emitted with
// LFAllowTrailingComma and emitList writes the separator after the last element
// when the NodeList has one. Both polarities are here on purpose.
declare function f({ a, }: { a: string }): number;
declare function f2({ a }: { a: string }): number;
declare function g([, b,]: [any, any]): void;
declare function g2([, b]: [any, any]): void;
declare function h([, x, , y, , , , z, , ,]?: string[]): void;
declare function k({ p: q, r: w, }: { p: number, r: number }): void;
const r = f; const r2 = f2; const s = g; const s2 = g2; const t = h; const u = k;
