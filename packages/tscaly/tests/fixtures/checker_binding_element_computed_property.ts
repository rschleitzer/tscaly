// Slice 56. THE COMPUTED PROPERTY NAME, and the reason the paragraph above
// check_variable_like_declaration can still call the `IsComputedPropertyName(name)`
// branch unreachable while this one reports.
//
// ★★★ THE TWO ARE DIFFERENT QUESTIONS ABOUT DIFFERENT NODES. A binding element's
// NAME is an identifier or a binding pattern — never computed — so the branch at
// the top of checkVariableLikeDeclaration stays out of reach for all three kinds
// that reach that function today, and its owner is the PropertyDeclaration arm.
// What CAN be computed is the binding element's PROPERTY name: `{[k]: v} = o` has
// propertyName `[k]` and name `v`. §3.5cz reassigned both branches to the binding
// element and was out by one; this file is the half that was right.
//
// ★★ THE TAG IS `check-computed-property-name` AND IT IS FIRST BY ONE LINE. The
// report for the type dimension (`get-type-for-binding-element-parent`) is the
// very next statement and record_unported keeps the FIRST, so a port that asked
// the two questions in the other order would answer the other tag on this file —
// which is the reference's order made visible, and it is one of the thirteen
// stage-1 units whose tag this slice moves.
//
// ★ The second line is the negative half: an ordinary renaming, whose property
// name is an identifier, which reports the type dimension instead.
var { [k]: v } = o;
var { a: b } = o;
