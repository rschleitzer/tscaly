// Slice 63. checkGrammarBreakOrContinueStatement, which is ported WHOLE — four ways
// to answer *this jump is fine* and five diagnostics for the ways it is not.
//
// ★★ FOUR OF THE FIVE ARE HERE. In order: an unlabeled `break` outside everything
// (TS1105), an unlabeled `continue` outside everything (TS1104), a labeled
// `continue` whose label sits on a BLOCK rather than on a loop (TS1115), and a
// labeled `break` naming a label that is not an ancestor at all (TS1116). The fifth
// — TS1107, the function boundary — has its own fixture and is UNREACHABLE.
//
// ★★★ THE TWO ARMS THAT ANSWER *fine* WITHOUT A LABEL ARE REACHABLE THROUGH ONE
// KIND EACH, AND ONLY BECAUSE THIS SLICE PORTED THE `do` AND THE `while`. A jump
// inside a loop needs the loop's arm to have walked into its body, and of the five
// iteration kinds only those two are here — so the last two lines exercise the
// walk's `default` arm, and a `for` spelled the same way would not be reached at
// all. The SwitchStatement arm of the same walk is unreachable for exactly that
// reason, one kind along.
break;
continue;
lbl: { continue lbl; }
missing: { break nosuch; }
do continue; while (1)
while (1) break;
