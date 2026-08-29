// Slice 97: the NORMALISATION LOOP — the arrow hop, the computed-name hop, and the
// two flags get_this_container carries.
//
// ★★★ AND IT IS A CONTAINMENT PROOF RATHER THAN A MEASUREMENT: NOT ONE `this` IN
// THIS FILE REACHES checkThisExpression, and the stops say why in one line each. An
// ARROW's body is checked deferred, so `() => this.x` stops at
// `check-function-expression-or-object-literal-method` before the arrow hop can be
// asked; a computed property name in a CLASS stops at `get-late-bound-symbol`, and
// in an OBJECT LITERAL at `check-object-literal`. So the loop is written, its two
// flags are threaded, and its input arrives with one of those three chapters.
//
// ★ The measured form of the same claim is the stop log old-against-new: every one
// of the 103 stage-1 arrivals at `check-this-expression` carried detail 109, the
// ThisKeyword — the arrow and computed-name spellings contributed none.
export {}

class C {
    x: number = 1

    // "Stop at the first arrow function so that we can tell whether `this` needs to
    // be captured" — then skip it, so the container is the METHOD and not the arrow.
    m(): number {
        const f = () => this.x
        return 1
    }

    // Two arrows deep: one hop is enough, because the hop is a WALK and not a step.
    n(): number {
        const f = () => () => this.x
        return 1
    }
}

// A computed property name IN A CLASS is a this container, which is the only thing
// includeClassComputedPropertyName does — and the report it makes possible is
// TS2465.
class D {
    [this.k]: number = 1
    k: string = "a"
}

// In an OBJECT LITERAL it is not: the same syntax walks past the literal to the
// container around it.
function outer() {
    const o = { [this.k]: 1 }
    return o
}
