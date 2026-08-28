// checkNullishCoalesceOperands' TS5076 — `||` and `??` mixed without parentheses.
declare const p: number | null;
declare const q: number | null;
const mixed = p || q ?? 0;
