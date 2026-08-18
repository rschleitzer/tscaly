// Slice 20 — JSX children with a broken INNER list, which is the only situation
// that reaches is_list_terminator(PCJsxChildren) at all: parse_jsx_children has its
// own loop, so that arm is consulted only through is_in_some_parsing_context, when
// an inner list cannot use the token it is looking at and asks every open list
// whether the token belongs to one of them.
//
// ★★★ THESE UNITS DO NOT GATE THAT ARM, and saying so is the point — a fixture whose
// header claims a gate it does not have is the §3.5ap trap. Measured: the control
// that makes is_list_terminator(PCJsxChildren) answer `false` is UNGATED even with
// all three units below, and the reason is structural rather than a coverage gap.
// is_in_some_parsing_context asks is_list_element(k, true) FIRST, and
// is_list_element(PCJsxChildren, ...) answers TRUE unconditionally — the reference's
// own `case PCJsxChildren: return true`. So while the child context is open the
// disjunction already says yes on every token, and the terminator arm cannot change
// its answer. INDISTINGUISHABLE by construction, not uncovered; the same reading the
// heritage-clause tightening in is_list_element already carries, and the reference
// has the arm too, which is why it is ported.
//
// What these three DO cover is the recovery itself: an inner list meeting `</` in
// child position, in the three shapes that put one there.
// @Filename: recovery.tsx
const a = <div>{[1, </div>}</div>;
// @Filename: args.tsx
const b = <div>{f(1, </div>}</div>;
// @Filename: attrs.tsx
const c = <div><span a=1 </div></span>;
