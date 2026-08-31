// Slice 113: the forks in front of onFailedToResolveSymbol, so each is a row a
// control can move — a primitive extended, implemented and used as a value, a
// value used as a type, a type used as a namespace, and the two missing-prefix
// members. The `export` fork lives in its own file, which has to be a module.
interface IE extends string {}
class CE extends number {}
class CI implements boolean {}
type T1 = { x: number };
let u = T1;
let v = 1;
type T2 = v;
type T3 = T1.x;
class K {
    static sm = 1;
    p = 2;
    m() { return sm; }
    n() { return p; }
}
namespace NS { export type Z = number; }
let w = NS;
