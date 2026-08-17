interface A { a: string, b: number }
interface B { a: string; b: number }
interface C { a: string
b: number }
type D = { c(): void, d(): void };
type E = { (): void, new (): D };
interface F { a }
