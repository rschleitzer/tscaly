// addOptionalityEx -> getOptionalType, the site where a union is INFERRED rather
// than written: an optional binding, parameter or property gets `T | undefined`.
// getOptionalType puts undefined FIRST in the constituent list, because that is
// where CompareTypes sorts it (1 << 2, ahead of string's 1 << 5), and its own
// first test -- `Types()[0] == undefinedType` -- is what makes `(T | undefined) |
// undefined` answer the same type rather than a second one.
declare function f(a?: string, b?: number): void;
declare let maybe: string | undefined;
class C {
    p?: string;
    q?: boolean;
    r?: string | undefined;
}
interface I {
    s?: number;
}
