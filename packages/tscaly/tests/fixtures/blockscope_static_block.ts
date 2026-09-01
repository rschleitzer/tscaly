// Slice 107. isUsedInFunctionOrInstanceProperty's static arm — the one place this
// chapter runs a FLOW analysis rather than a position comparison, and the only
// input the whole stage-1 corpus has for it.
//
// ★★★ isPropertyInitializedInStaticBlocks IS THE SAME SYNTHESIS
// is_property_initialized_in_constructor ALREADY DOES: a `this.x` property access
// with no source of its own, parented at the static block and given that block's
// RETURN flow node, so the flow walk answers whether the field is definitely
// assigned by the end of it. That is why this arm is ported and not a stop — every
// piece it needs was already standing.
//
// ★★★ ITS ANSWER IS UNOBSERVABLE HERE AND THE FILE SAYS SO RATHER THAN PRETENDING
// OTHERWISE. Both readings lead to the same report under this harness: with TRUE
// the after tail goes on to isPropertyImmediatelyReferencedWithinDeclaration, which
// answers TRUE for a sibling property of the same class and negates back to a
// report; with FALSE the walk runs out at the block-scope container and reports
// directly. The term that separates them is `emitStandardClassFields`, so the day a
// `useDefineForClassFields: false` case reaches the checker this file's four lines
// stop agreeing. What the fixture DOES buy is that the arm is REACHED — measured:
// it is the only unit in the stage-1 corpus that reaches it at all.
//
// ★★ THE POSITION WINDOW IS THE HALF NO FLOW ANSWER GIVES. Static blocks run in
// document order, so only the ones between the class's own start and the USE count:
// `Before` assigns in a block above the use, `After` in one below it, and only the
// first is in the window.
//
// ★ The assignment is written `Before.b` and not `this.b` deliberately. `this.b = 1`
// inside a static block reaches global-object-property-augment, a stop in another
// chapter, and the stop would take the rest of the unit's diagnostics with it — the
// file would then gate nothing (§3.5ap).

class Before {
    static { Before.b = 1; }
    static a = Before.b;
    static b: number;
}

class After {
    static a = After.b;
    static { After.b = 1; }
    static b: number;
}
