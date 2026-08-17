// A parameter's name is a BindingElement's name too — parseNameOfParameter goes
// through the same parseIdentifierOrPattern. Every position that takes a
// parameter list is exercised here.
function f([a], { b }) { }
function g([c] = d, { e } = h) { }
function i([j]: number[], { k }: any) { }
var l = ([m], { n }) => m;
var o = function ([p]) { };
class Q { r([s], { t }) { } }
declare function u([v]?: any): void;
