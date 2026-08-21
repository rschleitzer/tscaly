// slice 38 — the four arms of getInitializerSymbol and IsExpandoInitializer that
// are JAVASCRIPT-ONLY, which is why this unit is a `.js` file and
// binder_expando_initializer.ts is not.
//
//   K    a class DECLARATION is expando-extensible here            →  declares
//   Ke   a class EXPRESSION is an expando initializer here         →  declares
//   o    an EMPTY object literal with no type annotation           →  declares
//   p    a NON-empty object literal                                →  nothing
//   q    an empty one WITH a type — in a JavaScript file `@type` is a real
//        annotation, so `declaration.Type() != nil` and the arm refuses  → nothing
//   lt   a LET arrow: extensible here, because the arm's second disjunct is
//        IsInJSFile                                                →  declares
// @Filename: expando.js
class K {}
K.x = 1;
const Ke = class {};
Ke.x = 2;
const o = {};
o.x = 3;
const p = { y: 1 };
p.x = 4;
/** @type {{}} */
const q = {};
q.x = 5;
let lt = () => {};
lt.x = 6;
