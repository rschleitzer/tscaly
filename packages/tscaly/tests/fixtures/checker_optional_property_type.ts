// The optional half of addOptionalityEx, which is getOptionalType, which is a
// UNION — the one type family this port cannot make. It is behind
// strictNullChecks, TRUE under this harness, so the `?` is what reaches it and
// the same property without one does not.
type T = { x?: string };
