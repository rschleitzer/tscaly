type F = (a: string, b?: number) => void;
type C = new (x: object) => Date;
interface I {
    m: (p: string) => number;
    n: new () => I;
}
declare const f: <T>(t: T) => T;
