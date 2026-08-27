// A constructor OVERLOAD in a derived class: the missing-body early return and the
// extends test are two different guards, and only a derived class separates them.
class B { }
class C extends B {
    constructor(x: number);
    constructor(x: string);
    constructor(x: any) { super(); }
}
