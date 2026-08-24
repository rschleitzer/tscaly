// Slice 64. TS1431, the ONE diagnostic that survives checkGrammarForInOrForOfStatement's
// option dimension — and it survives BECAUSE of the derivation rather than in spite
// of it.
//
// ★★★ THE FILE MUST NOT BE A MODULE. `for await` at the top level of a script sets
// no AwaitContext flag, IsInTopLevelContext answers true, and the report is reached
// when IsEffectiveExternalModule is false — which is `is_external_module` alone here,
// because ES2022 is neither CommonJS nor in the Node16..NodeNext range. Add an
// `export {}` to this file and the diagnostic goes away, which is what its own
// message tells the user to do.
//
// ★★ THE moduleKind SWITCH THAT FOLLOWS IT REPORTS NOTHING, and both of its labels
// are dead for their own number: module_kind is ES2022 = 7, so the Node label is
// never taken, and language_version is ES2025 = 12 against ES2017 = 4, so the ES
// label breaks before its fallthrough. TS1309 and TS1432 are therefore unreachable
// under this harness — see controls-slice64.sh, where each is measured by moving the
// field rather than by asserting the number.
for await (const x of []) { }
