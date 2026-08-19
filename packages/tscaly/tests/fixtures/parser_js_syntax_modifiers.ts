// Slice 24 — the MODIFIER loop. Every modifier that is neither a decorator nor
// one of the five ModifierFlagsJavaScript admits is reported at its own range.
//
// The five that must stay SILENT are here as the negative half: `export`,
// `static`, `accessor`, `async` and `default` are all legal JavaScript. A test
// that only shows the reported ones cannot tell a working mask from a mask that
// reports everything.
// @Filename: modifiers.js
declare var a;

class C {
    public b;
    private c;
    protected d;
    readonly e;
    static f;
    accessor g;
    async h() {}
}

export default class D {}

export var i;
