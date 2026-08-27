// Slice 73. The negative half of TS2699: in an AMBIENT context a static
// `prototype` is not reported.
//
// ★★★ THE FLAG IS READ OFF THE CLASS AND NOT OFF THE MEMBER, which is what a
// declaration file exercises without a `declare` keyword in sight — every node in
// a .d.ts carries NodeFlagsAmbient, so `nodeInAmbientContext` is true for the
// class and the whole prototype test is skipped. The duplicate machinery is
// unaffected by that flag, which is why this file carries no duplicate.
export {};
declare class C {
    static prototype: number;
}
