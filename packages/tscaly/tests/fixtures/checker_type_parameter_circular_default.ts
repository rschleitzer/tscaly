// SLICE 81: TS2716, and it is blocked one level DEEPER than TS2313 is.
//
// getResolvedTypeParameterDefault detects circularity through the memo slot
// itself: it writes resolvingDefaultType before computing, and a recursive ask
// finds the marker and overwrites it with circularConstraintType. Reaching that
// recursion needs the DEFAULT's type node to ask for a default again, which
// happens inside fillMissingTypeArguments while resolving a GENERIC TYPE REFERENCE
// with too few arguments — `SelfReference` naming itself with none is the
// reference's own witness for this code. So the arm that runs here is the stop
// path, behind the same `get-type-from-type-node 184` row as its neighbour, and
// that path is why the marker has to be taken back OUT of the slot: one left
// behind would make a later ask read it as a recursive entry and INVENT a TS2716.
interface SelfReference<T = SelfReference> {}
interface PlainDefault<T = string> {}
