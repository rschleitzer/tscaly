// ★★★ A NEGATIVE PIN, and it is about REACHABILITY rather than about a report.
// Three of the reference's overload-agreement reports need a modifier only a
// class MEMBER can carry — public/private/protected (TS2385), abstract (TS2512)
// and static (TS2387/TS2388) — and nothing in this port walks a class's member
// list: checkClassLikeDeclaration stops at checkObjectTypeForDuplicateDeclarations.
// So this unit stops with THAT tag and none of the three fires, which is the
// difference between a report this slice ported and one it can be handed an
// input for.
class C {
    private p(a: string): void;
    p(a: number): void;
    p(a: any): void { }
    static q(a: string): void;
    q(a: number): void { }
}
