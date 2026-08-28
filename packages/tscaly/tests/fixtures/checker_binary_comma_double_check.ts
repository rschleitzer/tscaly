// The memo's SECOND half, and the shape stage 1 could not see. `co` has two
// declarations and no annotation, so check_variable_declaration reaches this
// initializer twice — once through getTypeOfSymbol and once in its own tail. The
// comma's RIGHT operand is an identifier, which stops, so the arm answers nil, and
// until slice 88's `expression_resolved` bit a nil was not cached: the second ask
// re-ran the check and re-emitted its TS2695. Two lines where the reference has
// one, on two units of the stage-2 corpus and none of stage 1.
declare const q: number;
var co = (3, q);
var co: any;
