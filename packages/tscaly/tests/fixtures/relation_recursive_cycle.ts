// The maybe stack's whole reason: comparing two SELF-REFERENTIAL types walks into
// itself, and the reference's answer is *a comparison already in progress is
// assumed to hold*. Without that assumption this pair does not terminate; with it
// the assignment is accepted and the unit COMPLETES.
// ★★★It is the leg of the termination story the missing relation CACHE does not
// carry, which is why it is ported and the cache is not — see the chapter header.
interface Node1 { next: Node1; v: number; }
interface Node2 { next: Node2; v: number; }
declare let n1: Node1;
declare let n2: Node2;
n1 = n2;
