// TS1023 (parameter must have a type annotation) and TS1096 (exactly one
// parameter): two of check_grammar_index_signature_parameters' reports never fire.
interface A { [a]: string; }
interface B { []: string; }
