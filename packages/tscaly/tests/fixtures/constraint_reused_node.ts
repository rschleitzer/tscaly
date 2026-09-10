// The printer's ONE node-REUSE site, and the witness for the whole table of
// formats slice 169 read off the oracle. Every constraint here is written so that
// the reused node and the canonical name DIFFER wherever the language lets them:
// `Array<string>` is the marker, because its canonical name is `string[]`.
//
// Three of these are REFUSALS rather than reuses and they are the controls:
// `unique symbol` prints the canonical `symbol` (no same-scope ancestor for a
// nil enclosing declaration), `ZZI` without its type argument prints the source
// spelling because the ERROR TYPE is not a reference, and `typeof zznothing`
// likewise.
declare namespace M { export interface E { z: number } }
interface ZZI<X> { x: X }
type ZZA = Array<string>;
declare function c01<T extends (1)>(t: T): void;
declare function c02<T extends Array<string>>(t: T): void;
declare function c03<T extends ReadonlyArray<number>>(t: T): void;
declare function c04<T extends string[]>(t: T): void;
declare function c05<T extends { (): string; }>(t: T): void;
declare function c06<T extends { new (): string; }>(t: T): void;
declare function c07<T extends { a: string; b?: number }>(t: T): void;
declare function c08<T extends keyof any>(t: T): void;
declare function c09<T extends typeof zznothing>(t: T): void;
declare function c10<T extends string | number>(t: T): void;
declare function c11<T extends string & number>(t: T): void;
declare function c12<T extends (x: string) => void>(t: T): void;
declare function c13<T extends new (x: string) => void>(t: T): void;
declare function c14<T extends [string, number]>(t: T): void;
declare function c15<T extends { [k: string]: number }>(t: T): void;
declare function c16<T extends 'a' | 'b'>(t: T): void;
declare function c17<T extends Record<string, number>>(t: T): void;
declare function c18<T extends { readonly a: string }>(t: T): void;
declare function c19<T extends null>(t: T): void;
declare function c20<T extends undefined>(t: T): void;
declare function c21<T extends ZZI<string>>(t: T): void;
declare function c22<T extends ZZI>(t: T): void;
declare function c23<T extends unique symbol>(t: T): void;
declare function c24<T extends { m(): void }>(t: T): void;
declare function c25<T, U extends keyof T>(t: T, u: U): void;
declare function c26<T extends T[]>(t: T): void;
declare function c27<T extends { a: { b: string } }>(t: T): void;
declare function c28<T extends readonly string[]>(t: T): void;
declare function c29<T extends `a${string}`>(t: T): void;
declare function c30<T extends { [P in keyof any]: string }>(t: T): void;
declare function d01<T extends [Array<string>, Array<number>]>(t: T): void;
declare function d02<T extends Array<string> | Array<number>>(t: T): void;
declare function d03<T extends Array<string> & ZZI<Array<number>>>(t: T): void;
declare function d04<T extends Array<string>[]>(t: T): void;
declare function d05<T extends readonly Array<string>[]>(t: T): void;
declare function d06<T extends (x: Array<string>, ...y: Array<number>[]) => Array<string>>(t: T): void;
declare function d07<T extends new (x?: Array<string>) => Array<string>>(t: T): void;
declare function d08<T extends { a: Array<string>; readonly b?: Array<number>; m(p: Array<string>): void; (): Array<string>; new (): Array<string>; [k: string]: any }>(t: T): void;
declare function d09<T extends { [P in keyof ZZI<string>]?: Array<string> }>(t: T): void;
declare function d10<T extends { -readonly [P in keyof ZZI<string>]-?: Array<string> }>(t: T): void;
declare function d11<T extends { [P in keyof ZZI<string> as `x${string}`]: Array<string> }>(t: T): void;
declare function d12<T extends ZZI<Array<string>>["x"]>(t: T): void;
declare function d13<T extends keyof ZZI<Array<string>>>(t: T): void;
declare function d14<T extends Array<string> extends Array<infer U> ? U : never>(t: T): void;
declare function d15<T extends `a${Array<string> extends any ? "b" : "c"}d`>(t: T): void;
declare function d16<T extends M.E>(t: T): void;
declare function d17<T extends [a: Array<string>, b?: Array<number>, ...c: Array<string>[]]>(t: T): void;
declare function d18<T extends (Array<string>)>(t: T): void;
declare function d19<T extends keyof (ZZI<Array<string>>)>(t: T): void;
declare function d20<T extends typeof M.zznope>(t: T): void;
declare function d21<T extends this>(t: T): void;
declare function d22<T extends { a: 'x'; b: "y"; c: 1; d: true; e: null; f: -1 }>(t: T): void;
declare function d23<T extends ZZA>(t: T): void;
declare function d24<T extends { m<U extends Array<string>>(p: U): void }>(t: T): void;
declare function d25<T extends { readonly [k: number]: Array<string> }>(t: T): void;
declare function d26<T extends Array<Array<string>>>(t: T): void;
declare function d27<T extends { a: Array<string> } & { b: Array<number> }>(t: T): void;
declare function d28<T extends { [x: string]: Array<string> }[string]>(t: T): void;
declare function d29<T extends import("./zznope").Q<Array<string>>>(t: T): void;
declare function d30<T extends ZZI<Array<string>> | null | undefined>(t: T): void;
declare function e01<T extends (() => Array<string>) | Array<string>>(t: T): void;
declare function e02<T extends { a?: Array<string> }>(t: T): void;
declare function e03<T extends Array<string>["length"]>(t: T): void;
declare function e04<T extends { "a-b": Array<string>; 1: Array<number> }>(t: T): void;
declare function e05<T extends abstract new () => Array<string>>(t: T): void;
declare function e06<T extends { a: Array<string>[] | undefined }>(t: T): void;
declare function e07<T extends [...Array<string>[]]>(t: T): void;
declare function e08<T extends { <U>(p: U): Array<string> }>(t: T): void;
declare function e09<T extends {}>(t: T): void;
c01;c02;c03;c04;c05;c06;c07;c08;c09;c10;c11;c12;c13;c14;c15;
c16;c17;c18;c19;c20;c21;c22;c23;c24;c25;c26;c27;c28;c29;c30;
d01;d02;d03;d04;d05;d06;d07;d08;d09;d10;d11;d12;d13;d14;d15;
d16;d17;d18;d19;d20;d21;d22;d23;d24;d25;d26;d27;d28;d29;d30;
e01;e02;e03;e04;e05;e06;e07;e08;e09;
