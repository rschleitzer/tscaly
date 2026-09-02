// A NAMESPACED intrinsic tag. Upstream `Node.Text()` CONSTRUCTS `a:b` from the two
// halves and looks that name up in JSX.IntrinsicElements, so the reference reports
// TS2339; this port stores no such buffer (ast.scaly's `text_is` says so at its own
// line) and stops rather than looking up a name it would have to invent. The
// fixture is the marker for that limit.
declare namespace JSX {
    interface IntrinsicElements { div: any }
}
const a = <a:b />;
