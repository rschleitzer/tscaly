// Slice 107. isPropertyImmediatelyReferencedWithinDeclaration — the walk that
// decides whether a field initializer reads another field IMMEDIATELY or only
// LATER, and the three exits that decide it.
//
// ★★★ THE ARROW IS THE WHOLE POINT OF THE FUNCTION. `x = this.y` is illegal and
// `x = () => this.y` is not, although the two differ in nothing a position
// comparison can see: both read a field before it is initialized, and only one of
// them does so while the object is being built. The reference's own comment says
// exactly that, and `Y` and `Z` are the two ways to reach it — a parameter property
// and a plain field, which take the after tail's two different `is_field` terms.
//
// ★★★ `VV` IS THE WALK'S OTHER EXIT, AND IT IS THE ONE A READER DELETES. The loop
// runs `while node <> declaration` and answers TRUE when it stops — reaching the
// declaration means the read happened inside it, which is what
// `p: number = this.p` is. Written as a loop condition upstream, it becomes a
// `break` here, and a `break` with no answer after it reads like a miss.
//
// ★★ WHAT THIS FILE DOES *NOT* REACH IS RECORDED AT ITS ROWS RATHER THAN LEFT
// SILENT. The function's `usage.End() > declaration.End()` early return and its
// BLOCK arm are unreachable from both of this chapter's callers, for a reason that
// is a proof rather than a corpus gap — see g12/g14/g25 in
// tests/controls-slice107.sh. They are written because they are the reference's,
// not because anything here can price them.

class Y {
    t = () => this.u;
    constructor(public u: number) { }
}

class Z {
    a = () => this.b;
    b = 1;
}

class VV {
    p: number = this.p;
}
