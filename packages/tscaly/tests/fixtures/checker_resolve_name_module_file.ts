// SLICE 79: the SOURCE FILE arm of namesShareScope, and it needs a MODULE to be
// reachable at all.
//
// ★★★ In a SCRIPT file the source file's locals are skipped by the walk
// (is_global_source_file) because upstream merges them into the globals table, so a
// top-level declaration is invisible on both routes here. In a MODULE they are in
// scope, the walk finds the `const`, and the container is the source file itself —
// the arm this fixture gates.
//
// * `declare` and no initializer: an initializer would stop the unit at
// check-type-assignable-to and make the file pin that row instead (slice 72).
export {};
declare const q: string;
{
    var q;
}
