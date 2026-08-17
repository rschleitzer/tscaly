// PERMANENTLY UNPORTED, and a red-producing control — as parser_types_linebreak
// is.
//
// A for-statement initializer is the one caller that parses its declarations
// with allowExclamation FALSE: a definite-assignment assertion is meaningless
// on a loop variable, so the reference refuses the `!` here and recovers with
// four diagnostics. Let the `!` through and our side completes a tree the
// reference does not have.
for (var x! = 0;;) ;
