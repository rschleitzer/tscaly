// An accessor named `constructor` in an INTERFACE. The report's third term is
// IsClassLike(node.Parent), and an interface is not class-like — so the term is
// what keeps TS1341 off this shape.
interface I {
    get constructor(): number;
}
