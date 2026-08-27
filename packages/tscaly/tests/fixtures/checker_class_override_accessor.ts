// Slice 74. An `accessor` field and a get accessor, both carrying `override`. The
// walk's only kind test is `IsConstructorDeclaration`, so an accessor is an
// ordinary member here — where slice 73's duplicate-member walk had to tell an
// accessor from a property, this one has no reason to.
export {};
class C {
    override accessor a: number = 1;
    override get b(): number { return 2; }
}
