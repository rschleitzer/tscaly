// slice 41 — ONE id per class, however many private members it has. GetSymbolId
// stores the number it draws in the symbol, so the second member finds it
// already there: `#x` and `#y` are both `%FE#1@…`, and a class's private members
// are therefore all in one namespace keyed by their own text.
//
// ★ It is the DRAW that is guarded, not the name. Drawing per member gives `#y`
// the number 2 here — both names wrong — and advances the counter twice, so every
// class after this one in a longer file is renamed as well. Control c3 measures
// the first half on four units; the second half is what binder_private_name_lazy.ts
// is for.
class C {
    #x = 1;
    #y = 2;
    m() { return this.#x + this.#y; }
}
