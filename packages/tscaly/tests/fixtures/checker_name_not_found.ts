// Slice 113: the four ways out of onFailedToResolveSymbol a TypeScript file
// reaches — a plain miss, a spelling suggestion, a feature-map name (whose lib
// branch keeps the CALLER's code and skips the suggester) and a namespace miss.
let a = noSuchNameAtAll;
let bananas = 1;
let c = banabas;
let d = Promise;
let e: NoSuchNamespace.T = 1;
