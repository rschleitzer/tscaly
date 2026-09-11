// TS2473: enum declarations must all be const or non-const.
// check_enum_declaration's report for it never fires over the corpus.
enum E { a }
const enum E { b }
