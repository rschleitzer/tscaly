// ★★★ TS2389, and the fixture is the same-name test seen from its FALSE side. An
// overload followed immediately by an implementation with a DIFFERENT name is not
// an overload set; the reference names the implementation and says what the name
// must be. The message's argument (that name) is not in a C line, so what is
// measured here is the code and the span.
//
// ★ It is the complement of the equal-name case the corpus already contains: the
// battery's g13 forces the comparison TRUE and g14 forces the third disjunct
// FALSE, and only a corpus holding BOTH sides can gate both rows.
function overloaded(x: string): void;
function different(x: string): void { }
