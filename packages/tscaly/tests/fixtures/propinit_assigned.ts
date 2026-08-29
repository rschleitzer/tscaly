// The other half: the synthetic `this.p` reference walked BACKWARD from the
// constructor's return flow node. Straight is what this slice can answer whole --
// the walk reaches the Assignment node, isMatchingReference's property-access arm
// says yes, and the declared type comes back without undefined, so no TS2564.
//
// The two BRANCHING classes below are the boundary and are here on purpose: a
// branch label unions its antecedents through narrowType, which is the next
// chapter, so the walk STOPS and this port makes no claim -- the reference reports
// TS2564 on PartlyAssigns.e and we do not. That is an under-report, which is what
// a stop is for; the direction that must never happen is the other one, and
// check_property_initialization's per-member mark is what prevents it.
class Straight {
    a: string;
    b: number;
    #c: string;
    constructor() {
        this.a = "x";
        this.b = 1;
        this.#c = "y";
    }
}
class Assigns {
    a: string;
    b: number;
    constructor(q: boolean) {
        this.a = "x";
        if (q) {
            this.b = 1;
        } else {
            this.b = 2;
        }
    }
}
class PartlyAssigns {
    d: string;
    e: string;
    constructor(q: boolean) {
        this.d = "x";
        if (q) {
            this.e = "y";
        }
    }
}
class OverloadedCtorOnly {
    g: string;
}
