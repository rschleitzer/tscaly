// tryBlock, catchClause, finallyBlock — the last two optional, and the absence
// of a catch makes `finally` required.
//
// The JSDoc'd catch on the last line is the control for a real asymmetry:
// parseCatchClause is the one clause-shaped routine in the reference that does
// NOT call withJSDoc, so that CatchClause carries flags 0 where every
// statement around it would carry 1 << 21.
try { a(); } catch (e) { b(e); } finally { c(); }
try { } catch { }
try { } finally { }
try { } catch (f) { }
try { } /** d */ catch (g) { }
