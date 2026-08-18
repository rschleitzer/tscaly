export = foo;
declare function foo(): void;
interface I { a: number }
type T = I | number;
declare namespace foo { const x: T; }
