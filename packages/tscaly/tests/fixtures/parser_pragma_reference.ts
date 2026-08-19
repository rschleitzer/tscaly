// Slice 23 — the comment pragmas. The only thing a parser yardstick can see of
// them is two diagnostics: TS1084 for a `<reference>` naming none of
// types/lib/path/no-default-lib, and TS1453 for a `resolution-mode` that is
// neither `require` nor `import`.
//
// Line by line: a bad resolution-mode; three well-formed directives that say
// nothing; no-default-lib, which swallows the directive whatever else it
// carries; an empty one and one with only an unknown argument, both TS1084;
// an upper-case tag name, which extractName lowercases; FOUR slashes, which is
// not a triple-slash comment at all; single quotes; and finally a directive
// below a statement, which is not a leading comment of position 0 and so is not
// a pragma.
/// <reference types="a" resolution-mode="bogus" />
/// <reference path="ok.ts" />
/// <reference lib="es5" />
/// <reference no-default-lib="true" />
/// <reference />
/// <reference foo="bar" />
/// <REFERENCE path="x" />
//// <reference path="y" />
/// <reference path='q' />
var z = 1;
/// <reference path="late" />
