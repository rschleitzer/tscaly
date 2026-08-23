// Slice 59. The negative half of checker_collision_require_exports.ts, and the
// term it isolates is the FILE's kind rather than anything about the declaration.
//
// ★★ NO `export {}`, so this is a SCRIPT: IsExternalOrCommonJSModule answers
// false, and a script emits no `require`/`exports` of its own for the name to
// collide with. Both declarations are silent here and both report in the twin —
// same names, same container, same emit format.
class require {}
enum exports {}
