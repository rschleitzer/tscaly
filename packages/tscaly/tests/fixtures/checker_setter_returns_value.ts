// TS2408: a set accessor's `return` may not carry an expression. The report needs
// the SIGNATURE only to get past checkReturnStatement's two grammar tests — it
// reads no type of its own, which is what makes it reachable while the whole
// expression dimension is still a stop.
class C {
    set x(v: number) {
        return v;
    }
}
