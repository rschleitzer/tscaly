// anyArrayType — createArrayType over the global Array, from a lib this
// compilation does not load. The reference reports TS7019 here; this port stops,
// which is the honest answer and is what the tag says.
declare function h(...r): void;
