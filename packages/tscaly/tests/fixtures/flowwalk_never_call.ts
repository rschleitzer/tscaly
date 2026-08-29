// A callee whose return type is `never` makes the call's successor UNREACHABLE,
// and only getEffectsSignature knows it -- which is a stop. isReachableFlowNode
// answers a bool, so that stop cannot travel out through the answer, and the
// arm's honest answer is *reachable*: the direction that INVENTS a TS2534.
// Reduced from conformance/controlFlow/neverReturningFunctions1, the one unit of
// 18 242 that caught it and none of the 1 473 at stage 1.
declare function fail(msg: string): never;
declare namespace ns { function panic(): never; }
class Thrower {
    throwIt(): never {
        throw new Error("x");
    }
}
class Derived extends Thrower {
    viaThis(): never {
        this.throwIt()
    }
    viaSuper(): never {
        super.throwIt()
    }
}
function viaFree(): never {
    fail("x")
}
function viaDotted(): never {
    ns.panic()
}
