// slice 37 — bindCallExpression. A bare `require(...)` anywhere in a JavaScript
// file makes it a CommonJS module even though it declares nothing itself: the
// file gets its module symbol and the two locals appear. IsRequireCall's second
// parameter is FALSE here, so the argument need not be a string literal —
// `require(x)` counts.
// @Filename: req.js
function f(x) {
    return require(x);
}
