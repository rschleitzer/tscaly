// Slice 111. The union constituent's PARENTHESIS, which the printer adds by
// PRECEDENCE and not by a list of kinds: a function or constructor type is below a
// union constituent's TypeOperator and is wrapped, everything else this printer
// builds is not. ★The source writes no parenthesized type node anywhere — an OPTIONAL
// member is what mints the union, which is the shape the defect was found in — and an
// object-literal constituent is left out because it reaches `get-reduced-union-type`.
declare const o: { m?(): void; c?: new () => string; k?: string };
