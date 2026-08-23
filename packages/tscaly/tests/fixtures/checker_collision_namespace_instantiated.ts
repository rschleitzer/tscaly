// Slice 59. The GetModuleInstanceState term of the require/exports check, in the
// only arm that reads it.
//
// ★★★ AN UNINSTANTIATED NAMESPACE EMITS NO OBJECT, so its name cannot collide —
// the reference's own comment. `namespace exports {}` is empty and therefore
// NonInstantiated: silent. `namespace require { export var x = 1 }` declares a
// value, so it is Instantiated and reports TS2441.
//
// ★★ THE TWO ARE ONE STATEMENT APART AND THE DIFFERENCE IS INVISIBLE IN THE TEXT
// of the declaration itself: it is a MAXIMUM over the body's exports, which is
// why the port asks the binder (Binder.get_module_instance_state) rather than
// looking at the node.
//
// ★ The namespace arm reaches the collision head only through the IDENTIFIER
// branch of checkModuleDeclaration — `declare module "m"` skips it — and the body
// is checked FIRST, so a statement inside a namespace can take the unit's tag
// before the header is looked at. Neither affects the report.
export {};
namespace exports {}
namespace require { export var x = 1; }
