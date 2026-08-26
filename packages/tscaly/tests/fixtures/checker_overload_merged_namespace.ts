// ★★★ THE KIND EQUALITY BETWEEN A DECLARATION AND ITS SUCCESSOR. `f` is one
// symbol with two declarations of DIFFERENT kinds, and the successor — the
// namespace — carries a name AND a body, which is the only combination in which
// the kind test decides anything: without it the reporter would read the
// namespace as a same-named overload and go quiet, losing the TS2391 the
// reference has.
function f(a: string): void;
namespace f {
    export var x = 1;
}
