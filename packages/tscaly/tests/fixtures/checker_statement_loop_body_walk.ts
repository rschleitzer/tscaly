// Slice 64. What four of the five arms buy that their own reports do not: the WALK.
//
// ★★★ A LOOP BODY IS A STATEMENT CONTAINER THIS PORT HAD NEVER ENTERED. Every
// diagnostic below is another slice's — TS1156 (a `let` in a bare branch, slice 53),
// TS1116 (a `break` naming no enclosing label, slice 63) and TS1313 (an `if` whose
// body is the empty statement, slice 63) — and not one of them was reachable inside a
// `for`, a `for-in`, a `for-of` or a `switch` clause before this slice, because
// nothing recursed into them.
//
// ★★ THAT IS WHY A STATEMENT ARM'S YIELD CANNOT BE READ OFF ITS OWN BODY, which
// slices 61, 62 and 63 each recorded from their own side. This slice's five arms carry
// five diagnostic codes between them and the corpus pays it back in codes they do not
// mention.
for (;;) let x = 1;
for (var a in {}) break nosuch;
for (var b of []) if (1) ;
switch (1) { default: let y = 2; }
