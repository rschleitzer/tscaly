// Slice 111. `t.alias` — the slot that decides whether a type literal prints as its
// own structure or as the NAME it was declared under. The last two are the negative
// controls: an alias over a PRIMITIVE names the shared intrinsic, which carries no
// alias slot, and an unaliased literal has none either.
type Lit = { x: number };
type Fn = () => void;
type Prim = string;
declare const a: Lit;
declare const b: Fn;
declare const p: Prim;
declare const raw: { x: number };
