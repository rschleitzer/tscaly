// slice 42 — the same class in TypeScript declares NOTHING from the assignment: a
// `.ts` class says what its properties are, and binding `this.a = 1` there would
// invent a member the language does not have.
//
// ★★★ AND THE MECHANISM IS NOT THE ARM'S OWN `IsInJSFile` GUARD, which is what
// this fixture was first written to show. The CLASSIFIER is the JavaScript test:
// `getAssignmentDeclarationKind` returns ThisProperty only from inside
// `if IsInJSFile(bin.Left)`, so in a TypeScript file the kind is never
// ThisProperty and bindThisPropertyAssignment is never called. Control c2 —
// dropping the guard — is UNGATED, which is the measurement that says so. The
// guard is ported because the reference has it, and it is a second lock on the
// same door.
//
// ★ The file is deliberately the same shape as binder_this_property.ts's, so the
// pair is a controlled comparison: one member symbol against none, with the
// SCRIPT KIND as the only difference.
class C {
    constructor() {
        this.a = 1;
    }
}
