// SLICE 87. getExportsOfSymbol' late-binding fork, taken. The static member's name
// is COMPUTED, so the reference would late-bind it and this port stops instead —
// `late-bound-exports`, the static twin of getMembersOfSymbol's `late-bound-
// members`. The two are separate tags because the two halves of one class disagree:
// a computed INSTANCE member does not stop the static side.
const k = "x";
class C {
    static [k]: string;
}
