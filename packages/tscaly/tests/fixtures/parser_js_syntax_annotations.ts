// Slice 24 — the ANNOTATION arm of checkJSSyntax: a type annotation is
// TypeScript syntax wherever it appears, and a body-less function-like takes
// precedence over its own return type (both are the same `case` upstream, and
// the signature diagnostic is the `if` half of it).
//
// The four hosts are the ones the reference lists: a variable declaration, a
// parameter, a function's return type, and the body-less form itself.
// @Filename: annotations.js
var a: number = 1;

function f(x: string) {}

function g(): void {}

function h();

// ★ A body-less signature WITH a return type reports the signature and NOT the
// annotation: the reference's `else if` makes the two exclusive, and this is the
// line that says which one wins. Measured: one diagnostic, 8017.
function i(): void;

class C {
    m(y: number): string {}
}
