interface A {}
interface B<T> {}
interface C<T extends string = string> {}
interface D extends E {}
interface F extends G, H {}
interface I extends J<number> {}
export interface K {}
declare interface L {}
interface M { a: string }
interface N<T> extends J<T> {}
