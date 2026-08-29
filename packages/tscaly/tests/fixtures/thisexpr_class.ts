// Slice 97, and the fixture the chapter opens on: the four class containers, which
// is where `this` actually answers a type. The file is a MODULE (`export {}`) for
// the reason propaccess_member.ts is one — a script's top-level names are merged
// into globals upstream and this port builds no globals table (§3.11).
//
// What the THISPIN reads off it: the CONTAINER the normalisation loop settled on,
// the ARM of tryGetThisTypeAtEx that answered, and the type. An instance member
// answers the class's `this` TYPE (arm 3) and a static one answers the class's own
// type (arm 4) — two arms, one container kind apart.
export {}

class C {
    x: number = 1

    m(): number {
        return this.x
    }

    static s: number = 2

    static sm(): number {
        return this.s
    }

    get g(): number {
        return this.x
    }

    set st(v: number) {
        this.x = v
    }

    constructor() {
        this.x = 3
    }

    // A property initializer is a this container of its own kind.
    y: number = this.x
}
