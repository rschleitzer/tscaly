// `do` visits its BODY before its condition — the one iteration form that
// does, and the child order says so. The one-line `do ; while (0) x;` is the
// es-discuss case the reference cites: the semicolon after `)` is OPTIONAL,
// not an ASI question, so this parses with no diagnostic.
do ; while (0) x;
do { a(); } while (b);
while (c) { d(); }
while (e) f();
