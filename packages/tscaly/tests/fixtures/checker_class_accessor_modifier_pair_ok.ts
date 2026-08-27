// Slice 73. Two `accessor` fields of one name — and the file that MEASURES why
// HasAccessorModifier cannot be gated through this function's diagnostics at all.
//
// ★★★ THE KIND IS UNOBSERVABLE, AND IT IS THE BINDER THAT DECIDES THAT. Only one
// combination distinguishes kind 2 from kind 1 — two accessors, where the switch
// falls through and reports nothing — and the binder never gives that combination
// a MERGED symbol: two `accessor` fields conflict, and so does an `accessor` field
// beside a getter (measured, one declaration each in both cases), so the
// `len(Declarations) > 1` guard stops them before the kind is read. Every shape
// that DOES merge — a plain field beside an `accessor` field, in either order —
// reports under both readings, 1-against-1 and 2-against-1 alike. The modifier
// test is transcribed for the reference's sake and nothing here can see it.
//
// ★★ THE BINDER AGREEMENT IS WHAT MAKES THAT A STATEMENT ABOUT THE REFERENCE and
// not about this port: the symbols yardstick compares this unit and matches, so
// the split symbols are the reference's own.
//
// ★ What the file still pins is the silence: neither `accessor` field may collect
// a diagnostic from this function.
export {};
class C {
    accessor a: number = 1;
    accessor a: number = 2;
}
