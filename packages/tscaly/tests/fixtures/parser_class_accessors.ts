class A { get x() { return 1; } set x(v) {} }
class B { static get y(): number { return 2; } }
class C { get() {} set() {} }
class D { get; set; }
let o = { get p() { return 1; }, set p(v) {} };
