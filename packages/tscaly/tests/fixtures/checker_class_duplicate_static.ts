// Slice 73. Two static members of one name — the staticNames map's own arm, and
// the only witness for the reporter's `isStatic == ast.IsStatic(member)` filter.
//
// ★★ THE INSTANCE MEMBER OF THE SAME NAME MUST NOT COLLECT A DIAGNOSTIC. The
// report is raised for the static pair, and reportDuplicateMemberErrors then walks
// every member whose symbol carries the name `a` — including the instance one,
// which is a different symbol with the same name. `checkStatic` true is what keeps
// it out, so this file reports exactly twice and not three times.
export {};
class C {
    static a: number = 1;
    static a: string = "x";
    a: boolean = true;
}
