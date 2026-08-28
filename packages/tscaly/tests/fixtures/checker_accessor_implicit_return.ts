// TS2378: a get accessor must return a value. The test is the binder's
// HasImplicitReturn flag with HasExplicitReturn unset — a reachability answer,
// not a control-flow one.
class C {
    get x(): number { }
}
