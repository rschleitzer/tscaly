// The rest parameter's TS2370, and the third frontier row this slice closes:
// `isTypeAssignableTo(paramType, ReadonlyArray<any>)` reaches
// structuredTypeRelatedToWorker's readonly-array arm, where `Array` and
// `ReadonlyArray` are DIFFERENT targets so the same-target variance arm does not
// fire and the comparison is between the two number index types.
// ★★★It COMPLETES, which is the whole point: before this slice the relation could
// not answer ONE of its 59 arrivals over the stage-1 corpus — every single one
// stopped at `common-property-check`.
function f(...a: number[]) {}
function g(...b: string[]) {}
