// Slice 107. checkPropertyNotUsedBeforeDeclaration, and the two arms of
// isBlockScopedNameDeclaredBeforeUse that only a class field reaches.
//
// ★★★ TS2729 IS A `this.` QUESTION AND NOT A POSITION ONE. `x = this.y` with `y`
// declared BELOW takes the after tail; `a = this.b` with `b` declared ABOVE takes
// the before tail and is still illegal, because an uninitialized property read
// through `this.` is not "declared before" — that is the reference's second
// conjunct, the one a `!` turns off. Both spellings are here, and a port that read
// only the position comparison is green on neither.
//
// ★★ THE PARAMETER PROPERTY IS ITS OWN ARM AND ITS OWN OPTION.
// `foo = this.bar` where bar is a constructor parameter property is illegal only
// under emitStandardClassFields, which is a SECOND derivation off
// useDefineForClassFields — the two agree here and differ upstream, so the field
// exists rather than the literal.
//
// ★★★ `Early` IS THE ONLY LINE THAT REACHES THE EXCEPTION'S OWN TERMS, and it was
// added after the first battery came back with the row UNGATED. Every other class
// here declares the property BELOW the use, so the position comparison is already
// false and the exception decides nothing; `Early` declares it ABOVE, uninitialized
// and without a `!`, which is the one shape in which the second conjunct is what
// makes the read illegal. §3.5v's `uncovered`, answered with a fixture.
//
// ★ The methods are the negatives: a use inside a method body is deferred, so
// isUsedInFunctionOrInstanceProperty answers true for it and nothing is reported
// however early the property stands.

class Derived {
    a = this.b;
    b = "abc";
}

class Below {
    x = this.y;
    y = 1;
    m() { return this.y; }
}

class Definite {
    p!: number;
    q = this.p;
}

class Optional {
    r?: number;
    s = this.r;
}

class Param {
    t = this.u;
    constructor(public u: number) { }
}

class Method {
    v = this.w();
    w() { return 1; }
}

class Early {
    e: number;
    f = this.e;
}
