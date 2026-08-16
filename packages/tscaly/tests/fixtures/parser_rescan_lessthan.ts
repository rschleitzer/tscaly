type A = Foo<<T>(x: T) => T>;
type B = Foo<<T>() => void, string>;
var c: Bar<<T>(y: T) => void>;
