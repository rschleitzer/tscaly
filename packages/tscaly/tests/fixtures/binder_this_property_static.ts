// slice 42 — the TABLE is chosen by IsStatic, and it is the whole content of
// getThisClassAndSymbolTable's second half: a static member's `this` is the class
// itself, so its assignment declares an EXPORT of the class symbol; an instance
// member's declares a MEMBER.
//
// ★★★ The two names are the same on purpose. `%FEexports` and `%FEmembers` are
// different tables, so `x` appears TWICE in the dump — two symbols, one name, and
// no duplicate diagnostic — which is the only way to see that the choice was made
// rather than defaulted. A port that always answered `members` would show one
// symbol with two declarations and still look plausible.
// @Filename: thisstatic.js
class C {
    static sm() {
        this.x = 1;
    }
    im() {
        this.x = 2;
    }
}
