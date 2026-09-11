// TS2304 through check_grammar_private_identifier_expression: `#y` in an `in`
// expression where no enclosing class declares it.
class C {
    #x = 1;
    m(o: object) { return #y in o; }
}
