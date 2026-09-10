// A stage-2 finding of slice 115: the type-parameter CONSTRAINT is the nodebuilder's
// one node-REUSE site, so the reference reprints the source — `<T extends (1)>`, with
// the parentheses — where a canonical name says `1`. Ported in slice 169; until then
// this unit was UNPORTED and the stop tag was the witness. `g` beside it is the
// control whose source spelling IS its canonical name, so the two answers coincide
// there and it completed all along — which is why the parenthesis was the shape that
// made a divergence reachable at all.
declare namespace N {
    declare function f<T extends (1)>(test: T): void;
}
