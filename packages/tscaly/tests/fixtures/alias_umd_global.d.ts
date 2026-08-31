// Slice 110, row g05's input: the shape that caught the invented TS2686. Our merged
// `N` carries only the NamespaceExportDeclaration because initialize_checker does not
// merge a `declare global` block's exports, where upstream's also carries the
// namespace's ModuleDeclaration — so the UMD arm's `every` test can only be wrongly
// TRUE here, and it stops instead of answering.
declare global { namespace N {} }
export = N;
export as namespace N;
