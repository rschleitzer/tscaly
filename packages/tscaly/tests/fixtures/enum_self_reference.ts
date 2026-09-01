// Slice 116: evaluateEnumMember's two reports, which are the only place the
// evaluator speaks for itself — a member whose initializer names ITSELF
// (TS2565, the `declaration == location` arm) and one that names a member
// declared AFTER it (TS2651).
//
// ★ It measures through diagcheck: a member with no constant value ends in
// checkTypeAssignableTo, a chapter away, so the unit's T section never prints.
enum Self { A = Self.A, B = C, C = 2 }
