// ★★ checkFlagAgreementBetweenOverloads' Ambient arm (TS2384), and it is the arm
// whose per-source-file grouping the reference exists for: overloads split
// between lib.d.ts and a user file need not agree, which is why the reference
// groups by SourceFile. This port binds ONE file, so the group is the whole list
// — see check_flag_agreement_between_overloads' note.
//
// ★★ THE SEPARATOR EARNS A SECOND REPORT AND IT IS NOT THE RESET'S. The `var`
// pushes the non-ambient overload away from the ambient one, so the loop's own
// consecutiveness test fires and TS2391 lands on the declaration BEFORE the gap —
// which is the reference's answer too. The ambient reset is measured by
// checker_overload_ambient_after_overload.ts instead, where the ambient
// declaration comes LAST: previousDeclaration is assigned at the end of every
// iteration regardless, so the reset is only ever visible on the declaration that
// PRECEDES an ambient one.
declare function k(a: string): void;
var separator = 1;
function k(a: number): void;
function k(a: any): void { }
