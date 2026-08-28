// An accessor with a COMPUTED name: checkComputedPropertyName and, one line on,
// hasBindableName's late-bound half.
const k = "a";
class C {
    get [k](): number { return 1; }
}
