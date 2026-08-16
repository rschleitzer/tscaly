let a = { m() {} };
let b = { *g() { yield 1; } };
let c = { async h() {} };
let d = { "s"() {}, 1() {}, [k]() {} };
let e = { m<T>(x: T): T { return x; } };
