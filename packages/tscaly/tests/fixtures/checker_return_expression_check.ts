// SLICE 112: checkReturnExpression — the assignability report behind an ANNOTATED
// return. Its conditional fork has no input here: `check-conditional-expression`
// is a wall one chapter over, so the branch pair never reaches this function.
function bad(): string { return 1; }
function ok(): number { return 1; }
function alsoBad(): number { return "s"; }
