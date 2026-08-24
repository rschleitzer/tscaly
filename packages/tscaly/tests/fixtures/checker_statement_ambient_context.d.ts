// Slice 63. The first line the seven arms SHARE, and the mechanism it lifts.
//
// ★★★ THE ONCE-BIT OF checkGrammarStatementInAmbientContext IS A PROPERTY OF THE
// BLOCK, and until this slice an ambient block containing an `if` was UNKNOWABLE:
// the arm was not ported, so spend_ambient_report_of_container marked the block and
// said nothing, because a diagnostic at a position the reference does not have is
// the one thing diagcheck fails on. Here the `if` is the first statement of the
// namespace body, its arm exists, and the TS1036 lands at the reference's own
// position — the first, not the first one whose arm happened to be written.
//
// ★★ AND THE SECOND AND THIRD STATEMENTS GET NOTHING, which is the once-bit doing
// its job: one report per block, not one per statement. Remove the bit and this file
// grows two diagnostics the reference does not have.
//
// ★ The last statement is a `break`, whose grammar check runs only when the ambient
// check answers FALSE — and it does, because the block's bit is already spent. So
// TS1105 is reported here and would not be if the `break` came first.
declare module M {
    if (1) { }
    try { } catch (e) { }
    break;
}
