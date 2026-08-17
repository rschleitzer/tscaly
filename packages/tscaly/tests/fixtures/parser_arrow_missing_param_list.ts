// A function or constructor TYPE whose `(` is absent gets a MISSING parameter
// list, which is not the same as an empty one — `new => c` is the shape, and
// parse_parameters answers create_missing_list() for it.
//
// It does NOT gate the difference, and that is worth saying rather than
// implying: typeHasArrowFunctionBlockingParseError is the only reader of the
// sentinel, and on this text the speculative arrow is already refused one line
// later by the `=>`/`{` test, so both answers produce this tree. Measured:
// making the predicate always answer TRUE is RED 3 (the call site is live),
// and never consulting it at all is UNGATED (it is never true here). The shape
// that makes it true upstream is `(function() {})`, a JSDoc function type this
// port does not have — so the discrimination belongs to the JSDoc slice.
a ? (b): new => c : d;
