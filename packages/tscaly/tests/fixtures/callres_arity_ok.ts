// Slice 108. The single non-generic candidate that RESOLVES — the chapter's whole
// product, and the one thing no gate in this package could see before the CALLPIN.
//
// ★★★ EVERY LINE HERE IS SILENT IN BOTH DIRECTIONS, which is why the fixture is
// pinned on the CALLPIN and not on diagcheck: the reference reports nothing about a
// call that resolves and neither does this port, so a chapter that stopped resolving
// altogether would leave the C section byte-identical. The rows are
// `L <pos> 214 1 <argcount> <paramcount> <minargs>`.
//
// ★★ THE OPTIONAL PARAMETER IS NOT A VARIATION, IT IS THE HARDEST LINE IN THE FILE.
// `h(a?: number)` gives its parameter position the contextual type
// `number | undefined`, and the union arm of isLiteralOfContextualType was a row
// until this slice — so `h(1)` could not resolve while `f(1)` could.
function f(a: number): number { return a; }
f(1);

function g(): void {}
g();

function h(a?: number): void {}
h();
h(1);

// A parameter with an INITIALIZER is optional too, and by a different accessor:
// get_type_of_parameter's addOptionality reads the initializer, not a question mark.
function i(a: number = 2): void {}
i();
i(3);
