// The three-part head: initializer, condition, incrementor, statement — every
// one of the first three optional, and each absent slot SKIPPED rather than
// counted, so `for (;;) ;` has exactly one child.
for (;;) ;
for (var i = 0; i < n; i++) { g(i); }
for (var a = 1, b = 2; ;) ;
for (h(); ; ) ;
for (; ; k()) ;
