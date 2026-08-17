// Object binding patterns. Shorthand, renamed, nested, rest, initializers and
// every property-name shape the reference admits here.
var { a } = x;
var { b, c } = x;
var { d: e } = x;
var { f = 1 } = x;
var { g: h = 2 } = x;
var { ...i } = x;
var { j, ...k } = x;
var { l: { m } } = x;
var { n: [o] } = x;
var { "p": q } = x;
var { 0: r } = x;
var { [s]: t } = x;
let { u }: { u: number } = x;
for (var { v } of w) ;
