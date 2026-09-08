// Slice 147's PROBE, and it is UNPORTED on purpose — read its header before
// deleting it for looking inert.
//
// ★★★ WHAT IT PINS IS CONTAMINATION BETWEEN TWO CLASSES' `this.foo`. C1 alone
// and C5 alone each answer what the reference answers: the port narrows C5's
// second read to `number[]` (`T 212 70 78 number[]` in the isolated file, and no
// stop at all). TOGETHER the port answers `number[] | undefined` at that node
// and `flow-assignment-automatic-assigned-type` fires TWICE. So C1's presence —
// a this-property assigned in a CONSTRUCTOR — makes C5's this-property, assigned
// only in a METHOD, take the AUTO branch, and the declared type of a method-only
// assignment declaration is what the successor has to fix.
//
// ★★★ NO YARDSTICK IS RED ON IT TODAY and that is stated here rather than left
// to be rediscovered: the unit STOPS, so the type dump is UNPORTED and not
// compared, and with the six text-decided codes of
// report_object_possibly_null_or_undefined_error taken back out (see its header)
// the port emits no diagnostic either, so diagcheck is green on it too. The
// finding is visible in ONE command and nowhere else:
//
//     tests/out/tscaly_types --stops tests/fixtures/checker_this_property_flow_probe.js
//
// two `flow-assignment-automatic-assigned-type`, against none for either class
// on its own. ★It is committed anyway for the reason every UNPORTED fixture is:
// the shape is in the corpus, so the day the chapter lands the unit turns green
// by itself and nobody has to remember this paragraph.
class C1 {
    constructor() {
        this.foo = [3];
        this.foo = [this.foo[0] * 2];
        this.foo;
    }
}
class C5 {
    method1() {
        this.foo = [3]
        this.foo = [this.foo[0] * 2]
        this.foo;
    }
}
