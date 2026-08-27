// SLICE 82: the file that makes unwrapReturnType's ORDER observable. An async
// generator carries BOTH flags, and the reference asks the generator question first
// — so the stop this unit logs is the iteration one and never the awaited one.
// ★The witness is the stop LOG and not the work-list tag: checkSignatureDeclaration
// resolves the same annotation one call earlier and record_unported is first-wins.
async function* asyncGeneratorAnnotated(): void {
}
