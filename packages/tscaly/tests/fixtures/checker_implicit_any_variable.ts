// TS7005, and the reason an AMBIENT declaration is the shape that reports: the
// control-flow `auto` type is only for a non-ambient, non-exported var or let, so
// `declare var` skips it, has no initializer and nothing to infer from, and the
// widener answers `any` plus this diagnostic. A plain `var q;` answers autoType
// instead and reports nothing — which is why the negative control is in the same
// file rather than in another fixture.
declare var q;
var p;
