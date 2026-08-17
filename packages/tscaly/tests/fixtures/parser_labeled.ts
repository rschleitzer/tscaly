// A label is recognised AFTER the fact: the reference parses an expression and
// then asks whether it turned out to be a bare identifier followed by a colon.
// It belongs to this slice because `break outer` is the only reason a label
// exists.
outer: for (;;) { break outer; continue outer; }
inner: while (a) { break inner; }
b: c: d();
break;
continue;
