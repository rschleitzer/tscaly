// Slice 56. THE DEFERRAL — `type F = ({a: string}) => void`, the reference's own
// example, in the one shape this port's walk can reach: a renamed binding element
// in the pattern of a parameter of a function that has NO BODY.
//
// checkVariableLikeDeclaration's binding-element block appends such a node to
// renamedBindingElementsInTypes and RETURNS; the diagnostic (TS2842, *'{0}' is an
// unused renaming of '{1}'*) comes at the end of the file from
// checkUnusedRenamedBindingElements, which needs the symbol and the
// reference-links table. So the port carries the WRITER and reports at the reader.
//
// ★★★ THE READER'S REPORT IS SHADOWED AND THE WRITER'S RETURN IS NOT. The reader
// runs LAST, after every statement, and the only route to the writer is a
// parameter — which this walk reaches only through a FunctionDeclaration, whose
// arm ends in `check-function-or-constructor-symbol`. So the reader's tag can
// never be first and **0 units of either corpus carry it** — nor does any shape
// slice 56's battery could build, which is the correction
// checker_binding_element_renamed_in_variable.ts carries. The RETURN, by
// contrast, decides what `h` answers: with it the binding
// element says nothing and the file's tag is the function's own report; without
// it the element reports `get-type-for-binding-element-parent` one step earlier.
//
// ★★ THAT DIFFERENCE IS A TAG AND NOT A DIAGNOSTIC, which is why
// controls-slice56.sh carries a second instrument. diagcheck compares C lines and
// this block produces none — an arm can be wholly wrong here and every diagnostic
// in the corpus still be right.
//
// ★ `h2` is the contrast on ONE term: a binding element with no property name is
// not a renaming, so it does not defer and reports the type dimension. It sits
// after `h` deliberately — the file's tag is its FIRST report, so a contrast line
// must not be able to answer for the line under test.
declare function h({a: b}): void;
declare function h2({a}): void;
