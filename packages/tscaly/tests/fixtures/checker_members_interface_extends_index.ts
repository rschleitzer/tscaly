// SLICE 85. The BASE LOOP. `B` declares no index signature of its own; its index
// infos come from resolveObjectTypeMembers' base loop, which asks
// getIndexInfosOfType of the base and keeps every key the derived type does not
// already have. So checkIndexConstraints gets past its first line on B, and it
// can only do that through the loop.
interface A {
    [k: string]: string;
}
interface B extends A {
}
