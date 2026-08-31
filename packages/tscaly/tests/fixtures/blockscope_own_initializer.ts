// Slice 107. The VariableDeclaration arm of isBlockScopedNameDeclaredBeforeUse's
// BEFORE tail — `let a = a`, where the declaration IS textually first and is
// nonetheless unusable.
//
// ★★★ THE BEFORE TAIL IS NOT THE AFTER TAIL'S COMPLEMENT, and this file is what
// says so with a number. `declaration.Pos() <= usage.Pos()` is true for every line
// below, so the whole file takes the tail whose default answer is TRUE — and the
// three reports come out of isImmediatelyUsedInInitializerOfBlockScopedVariable,
// the one term in that tail with an input here. A port that answered `true` for the
// before tail wholesale would be green on the file that carries the three codes and
// silent on this one.
//
// ★★ THE FUNCTION IS WHAT MAKES THE SCOPE TEST OBSERVABLE, AND THE IIFE IS WHAT
// SEPARATES THE TWO READINGS OF IT. isSameScopeDescendentOf walks from the use up
// to the declaration and stops at the first function-like it meets — but only when
// that function is not immediately invoked, because an IIFE runs at the
// declaration's own position and is therefore transparent. So `k` is legal for
// exactly the reason `a` is not, and `e` is illegal AGAIN although its use sits
// inside a function: three spellings, one walk, and the middle one is the only one
// no `pos` comparison can decide.
//
// ★ `e` carries its type and its callee's return type on purpose. Inferring either
// reaches getReturnTypeFromBody, which this port stops in, and the stop would take
// the rest of the unit's diagnostics with it — the line would then be a fixture
// that gates nothing (§3.5ap).

declare const n: number;

let a = a + n;

let c: number = c;

let e: number = (function (): number { return e; })();

let k = function () { return k; };
