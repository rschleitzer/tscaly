// Slice 117 — areDeclarationFlagsIdentical, at BOTH of its call sites and with the
// branch that is an EXEMPTION rather than a shortcut.
//
// ★★ THE CLASS PAIR IS THE LIVE HALF: a `private` and a `public` declaration of one
// property is TS2687 (beside the duplicate-identifier report), and the modifier list
// compared is exactly six flags wide — private, protected, async, abstract, readonly,
// static — so a difference in anything else is not reported at all.
//
// ★★ THE FUNCTION BELOW IS THE EXEMPTION. A parameter against a variable answers
// TRUE before optionality is compared, because *differences in optionality between
// parameters and variables are allowed*; what the pair DOES report is the subsequent
// declaration's TS2403, from the other branch of the same fork.
declare class C {
    private p: number;
    p: number;
}
function fq(a?: number) { var a: number; }
