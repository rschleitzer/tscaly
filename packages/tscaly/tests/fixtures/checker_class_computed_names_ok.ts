// Slice 73. Two computed member names are not a duplicate, and this file is what
// makes the `len(Declarations) > 1` guard observable.
//
// ★★★ TWO COMPUTED KEYS BIND TO ONE NAME. The binder cannot evaluate `[k1]` and
// `[k2]`, so both members land under the same internal name and the maps see it
// TWICE — but they are two SYMBOLS, one declaration each, so the guard stops the
// state machine before the second sighting can be read as a duplicate. Drop the
// guard and this legal class collects an invented TS2300 pair; it is the only
// fixture that can say so, because every other multiple-sighting shape here has a
// merged symbol behind it.
export {};
const k1 = "a";
const k2 = "b";
class C {
    [k1]: number = 1;
    [k2]: number = 2;
}
