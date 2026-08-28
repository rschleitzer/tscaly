// Slice 91. resolveName's four message-gated in-loop steps, and the measurement
// that says which of them a VALUE caller can reach.
//
// ★★★ THREE OF THE FOUR ARE UNREACHABLE FROM getResolvedSymbol AND THE TERM THAT
// DECIDES IT IS THE MEANING MASK. The class-members, base-class-expression and
// computed-property-name steps all look the name up with `meaning &
// SymbolFlagsType`, and getResolvedSymbol asks for `Value | ExportValue` — so the
// mask is 0, lookup_symbol answers null on its first line, and the report is
// never reached. TS2302, TS2562 and TS2467 wait for a caller in a TYPE position,
// which this port does not have yet. The reference answers TS2304 on both lines
// below, which is the port's own wall (§3.11) and a documented LOSS.
//
// ★ The fourth step — the enum member reached from another file — IS reachable,
// because EnumMember is part of SymbolFlagsValue; its report is dead behind
// isolatedModules instead. The `break` it guards is live and is what makes
// `E.A`-less member access inside the enum body resolve at all.
class A<T> {
  static x = T;
}

class B<T> {
  [T]() {}
}

enum E {
  A = 1,
  B = A + 1,
}
