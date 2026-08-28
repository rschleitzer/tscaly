// SLICE 85. The `%FEnew` member, the second half of resolveDeclaredMembers' and
// resolveAnonymousTypeMembers' signature pair.
interface Arg {
    a: string;
}
declare const constructable: { new (x: Arg): Arg };
