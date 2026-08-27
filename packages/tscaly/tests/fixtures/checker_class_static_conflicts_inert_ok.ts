// Slice 74. THE HEAD OF THE WORK LIST, AND ITS WHOLE OBSERVABLE CONTENT IS THAT
// NOTHING HAPPENS. checkClassForStaticPropertyNameConflicts reports TS2699 for a
// static member named `name`, `length`, `caller` or `arguments` — all four are
// here — and it returns at its own first line because
// GetUseDefineForClassFields() is TRUE under this harness: the option is an unset
// Tristate, so the reference falls through to `GetEmitScriptTarget() >=
// ScriptTargetES2022`, which is ES2025 >= ES2022.
//
// ★★★ THE REFERENCE IS SILENT HERE TOO, and that is the claim this fixture pins.
// tests/oracle/types.go builds its CompilerOptions with SkipDefaultLibCheck and
// NoErrorTruncation and nothing else, so the option is unset on BOTH sides. A
// battery row that substitutes `false` for the field turns four TS2699 lines on
// and this file red, which is the only instrument that function has.
export {};
class C {
    static name: string = "x";
    static length: number = 0;
    static caller: unknown = null;
    static arguments: unknown = null;
}
