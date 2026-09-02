// isConstContext is called for its EFFECT and not for its value: it asks
// getContextualType, which for an object literal on the right of an assignment
// walks up to the assignment and checks its LEFT — and the left here is a class,
// so each ask reports TS2629. createObjectLiteralType's first line is one such
// ask, and dropping it (reusing checkObjectLiteral's outer inConstContext) loses
// exactly one diagnostic. The `|| 1` line is the negative control: no object
// literal, so the count does not depend on that line at all.
class Mocked {
    myProp: string;
}
class Tester {
    a() {
        Mocked = {};
    }
    b() {
        Mocked = Mocked || function () {
            return { myProp: "test" };
        };
    }
    c() {
        Mocked = Mocked || 1;
    }
}
