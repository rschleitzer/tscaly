// Slice 63. checkCatchClause's three branches over the catch variable's shape, of
// which two are ours whole and one is behind the type system.
//
// ★★ THE REDECLARATION WALK IS THE FIRST TIME THE CHECKER READS A LOCALS TABLE OF A
// NODE THAT IS NOT ITS ARGUMENT: it walks the CATCH CLAUSE's locals — the caught
// names — and looks each up in the BLOCK's, so the report lands on the inner `let`
// and not on the catch parameter. Line 2 is that.
//
// ★★★ LINE 3 IS THE BRANCH WE CANNOT ANSWER. `catch (e: string)` needs the
// annotation RESOLVED before *must be any or unknown* can be decided, so the arm
// reports `get-type-from-type-node` and says nothing — the reference has a TS1196
// there that we do not. It is a gap in the MIDDLE of the unit's C section, which is
// the relation diagcheck asserts and the reason it stays green through it.
//
// ★★★ LINES 3–5 ARE THREE NEGATIVES OF LINE 2 AND ONLY TWO OF THEM MEASURE ANYTHING,
// which is a finding the battery produced rather than one that was written down first.
// The obvious negative is `var e` — `var` is FUNCTION-scoped, so the reference reports
// nothing — and it turned out to be the WRONG one: a hoisted `var` is not in the
// BLOCK's locals at all, so the lookup answers null and the flag test is never
// reached. g21 removing that test moved NOTHING with this line alone. A block-scoped
// FUNCTION and a CLASS are the negatives that do reach it: both ARE in the block's
// locals and neither carries SymbolFlagsBlockScopedVariable, so dropping the test
// invents a TS2492 on each. **A negative that does not reach the branch it is aimed
// at is not a negative**, and the two spellings are indistinguishable from the
// outside — the reference is silent on all three.
//
// ★★ LINE 5 IS THE NEGATIVE OF LINE 4, and it is the argument for the HOLE. `any` is
// exactly what the reference permits, so a port that answered the annotation branch
// with an unconditional TS1196 would be right on line 4 and would invent a
// diagnostic here — which is why reporting `get-type-from-type-node` and saying
// nothing is the only sound direction, and why the suppression is a measurement
// (controls-slice63.sh's g20) rather than a preference.
//
// ★ The three branches are an else-CHAIN and not three tests: a catch variable with
// an annotation never reaches the initializer question, and one with an initializer
// never reaches the redeclaration walk. Reading them as independent would produce
// two diagnostics on line 1.
try { } catch (e = 1) { }
try { } catch (e) { let e; }
try { } catch (e) { var e; }
try { } catch (e) { function e() {} }
try { } catch (e) { class e {} }
try { } catch (e: string) { }
try { } catch (e: any) { }
