// Slice 97: TS2683, the one report of this chapter that needs the TYPE and needs it
// to be ABSENT. noImplicitThis is TRUE under this harness — the fourth strict-family
// option — so a function that names `this` and has no `this` parameter, no class
// around it and no contextual type reports here.
export {}

function f() {
    return this
}

function g() {
    function h() {
        return this
    }
    return h
}

const k = function () {
    return this
}
