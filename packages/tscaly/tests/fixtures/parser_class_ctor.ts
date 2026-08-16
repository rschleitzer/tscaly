class A { constructor() {} }
class B { constructor(x: number, private y: string) {} }
class C { "constructor"() {} }
class D { "other"() {} }
class E { constructor(); constructor(x: number); constructor(x?: number) {} }
class F { constructor<T>(x: T) {} }
