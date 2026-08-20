type A = { a: number; b(): void };
let x: { c: string };
type B<T> = { [K in keyof T]: T[K] };
type C = { (): void; new (): A; [k: string]: unknown };
