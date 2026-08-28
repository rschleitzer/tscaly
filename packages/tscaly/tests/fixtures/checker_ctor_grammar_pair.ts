// BOTH constructor grammar violations on one declaration. The reference's `&&` is a
// SUPPRESSION: the type-parameter report withholds the type-annotation one, so this
// carries ONE diagnostic and reading the two checks as independent gives two.
class C {
    constructor<T>(): void { }
}
