// SLICE 85. addInheritedMembers over TWO bases, and the index infos of both. The
// second base's `[j: number]` is a key the first did not bring, so both survive
// the findIndexInfo filter.
interface A {
    a: string;
    [k: string]: string;
}
interface B {
    b: string;
    [j: number]: string;
}
interface C extends A, B {
    c: string;
}
