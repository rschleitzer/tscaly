// The deprecated spelling. The reference reports
// Import_assertions_have_been_replaced_by_import_attributes (2880) and parses
// the clause anyway, storing the word it FOUND on the node.
type A = import("m", { assert: { type: "json" } });
