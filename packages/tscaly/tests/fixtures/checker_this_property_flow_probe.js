// Slice 147's PROBE, and slice 148 is where what it pins was FIXED. It is still
// UNPORTED — read the header before deleting it for looking inert.
//
// ★★★ WHAT IT PINNED WAS CONTAMINATION BETWEEN TWO CLASSES' `this.foo`, and the
// cause was not in either class. C5's two reads narrow to `number[]` when the
// class stands alone; with C1 in front of them they came out
// `number[] | undefined`, `report-object-possibly-null-or-undefined` fired on
// the second one and the reporter's six text-decided codes then invented a
// TS2532 the reference does not report. **The cause was
// `get_type_of_expression` testing `is_unported()` — the unit-wide LATCH — where
// a per-call `unported_mark()` delta belonged**: C1's read stops
// (`flow-assignment-automatic-assigned-type`), the latch closes for the rest of
// the unit, and every later expression answers null, so the assignment that
// narrows C5's property stopped being seen. The name of the property does not
// matter and neither does the second class; ORDER does. Thirty-one sites carried
// the same test and all of them moved to the mark.
//
// ★★★ IT IS NOT THE PROBE'S OWN COMMAND THAT SHOWS IT — the command has to run
// from the REPO ROOT, or the lib is not found (`UNPORTED 0 lib 0`) and every
// class answers nothing:
//
//     packages/tscaly/tests/out/tscaly_types --stops \
//       packages/tscaly/tests/fixtures/checker_this_property_flow_probe.js
//
// Today that prints exactly the two `flow-assignment-automatic-assigned-type`
// and the one `check-arithmetic-operand-type` that C1 records ALONE, and nothing
// for C5. Before the fix it printed those plus a
// `report-object-possibly-null-or-undefined` and a second arithmetic stop, both
// belonging to C5.
//
// ★ The unit still STOPS, on C1's own wall — the assigned type of an `auto`
// declared type, which is a measured non-termination and not this slice's — so
// no yardstick is red or green on it. It is committed for the reason every
// UNPORTED fixture is: the shape is in the corpus, so the day that chapter lands
// the unit turns green by itself.
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
