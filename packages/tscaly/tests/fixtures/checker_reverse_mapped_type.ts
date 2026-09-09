// Slice 160. The REVERSE-MAPPED TYPE — inferring a source to a homomorphic
// mapped type `{ [P in keyof T]: X }` by building an object with the source's
// property names whose types are inferred BACKWARDS through X.
//
// ★★★ THE FOUR SOURCE SHAPES ARE THE CHAPTER'S FORKS, one line each below: an
// object literal (the lazy ReverseMapped type), an ARRAY and a TUPLE (both
// mapped eagerly, element by element), and an INDEX SIGNATURE (one reverse
// inference for the whole signature). A source that is none of these — no
// string index, no properties — is not reverse mappable at all and the call
// falls back to inferring nothing.
//
// ★★★ AND THE LAST TWO ARE ABOUT THE PRINTER RATHER THAN THE INFERENCE, which
// is why they are in the same fixture: a reverse-mapped type's index signature
// is ELIDED to `any` however well the value was inferred, and a property of a
// reverse mapping over a NON-ANONYMOUS type is elided too (`{ m: { w: any } }`
// below, where the inference itself answers `number`). Both come out of the
// reference's node builder, so a port that computed the right types and printed
// them would be wrong in a way no inference test can see.
declare function make<T>(x: { [K in keyof T]: () => T[K] }): T;
const fromLiteral = make({ a: () => 1, b: () => "s" });

declare function same<T>(x: { [K in keyof T]: T[K] }): T;
const fromArray = same([1, 2, 3]);
const fromTuple = same([1, "a"] as [number, string]);

declare function opt<T>(x: { [K in keyof T]?: T[K] }): T;
const fromOptionalTuple = opt([1, "a"] as [number, string?]);

declare const withIndex: { [k: string]: () => number };
const fromIndexSignature = make(withIndex);

declare const readonlyIndex: { readonly [k: string]: number };
const fromReadonlyIndex = same(readonlyIndex);

interface Fixed { w: number; v: string }
declare const overFixed: { m: Fixed };
declare function twice<T>(x: { [K in keyof T]: { [J in keyof T[K]]: T[K][J] } }): T;
const nestedOverInterface = twice(overFixed);

declare function nested<T>(x: { [K in keyof T]: { [J in keyof T[K]]: () => T[K][J] } }): T;
const nestedAnonymous = nested({ a: { p: () => 1 } });
