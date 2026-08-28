// SignatureFlagsConstruct and SignatureFlagsAbstract: a constructor of an
// abstract class carries both, a constructor type node carries Construct and
// takes Abstract off its own modifiers.
abstract class A {
    constructor() {
        return;
    }
}
type Ctor = abstract new () => A;
