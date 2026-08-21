// slice 41 — the same TEXT in two classes is two symbols, which is the whole
// reason the name carries an id. `GetContainingClass` is `FindAncestor(node.Parent,
// IsClassLike)`, so the INNERMOST class-like wins and Inner's `#o` is `%FE#3@#o`
// against Outer's `%FE#2@#o`.
//
// ★ The numbering follows the WALK and not the nesting: the class expression on
// the first line draws 1, Outer draws 2 at its own field, and Inner draws 3 only
// when the method body it sits in is bound. So this fixture pins the ORDER the
// ids are handed out in as well as the names.
const K = class {
    #a = 1;
};

class Outer {
    #o = 1;
    m() {
        class Inner {
            #o = 2;
        }
        return new Inner();
    }
}
