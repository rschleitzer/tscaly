// TS2378: a get accessor whose body's end is REACHABLE and which has no
// `return` anywhere lacks a value. The three neighbours must stay silent — one
// that always returns, one whose end is unreachable, and an ambient one.
class Accessors {
    get missing() {
    }
    get present(): number {
        return 1;
    }
    get unreachableEnd(): number {
        throw new Error();
    }
    get conditional(): number {
        if (Math.random() > 0.5) {
            return 1;
        }
    }
    set both(v: number) {
    }
}

declare class Ambient {
    get declared(): number;
}
