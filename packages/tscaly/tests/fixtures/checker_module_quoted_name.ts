// Slice 50. TS1035 — `Only ambient modules can use quoted names` — which is the
// module arm's own grammar report and the only one of this family's reports that
// goes through grammar_error_on_node rather than grammar_error_on_first_token: it
// points at the NAME, so its span comes from the binder's error_range_for_node.
//
// ★★ THE FILE MUST NOT BE A .d.ts, and that is the condition being pinned. The
// report is guarded by `!inAmbientContext`, and every statement of a declaration
// file is ambient — so the same line in a .d.ts is silent. Two fixtures would say
// it; one fixture in the wrong file would say nothing and look like a pass.
module "foo" { }
