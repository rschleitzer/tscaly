// Slice 117 — `const {a} = o` is an INDEXED ACCESS, and this fixture is the
// chapter's whole shape in six lines.
//
// ★★ EACH BINDING'S TYPE IS `(typeof src)["name"]` COMPUTED, not the annotation
// copied: `p` is `number` because the property is, and `q` is `string`.
// A renamed element (`r: renamed`) takes the PROPERTY name for the index and the
// BINDING name for the declaration, which is the one place the two differ.
declare const src: { p: number; q: string; r: boolean };
const { p, q, r: renamed } = src;
