// TS1181: `unique symbol` is only allowed on a variable in a variable statement.
// check_grammar_type_operator_node's report for it never fires over the corpus.
interface I { x: unique symbol; }
type T = unique symbol;
let ok: unique symbol;
