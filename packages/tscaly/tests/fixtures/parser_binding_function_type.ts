// skipParameterStart's binding-pattern arm, which slice 5 recorded as
// UNANSWERABLE and this slice answers. `(` followed by something that skips as
// a parameter start and then a `:` is unambiguously a FUNCTION TYPE, so this
// must not be read as a parenthesized type.
var f: ([a]: number[]) => void;
var g: ({ b }: any) => void;
var h: ([c], { d }) => void;
