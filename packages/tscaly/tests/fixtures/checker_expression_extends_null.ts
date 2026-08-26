// `extends null` is the one shape of a class heritage clause whose base
// expression this port can type, and the reference's TS2507 guard reads
// `baseConstructorType != c.nullWideningType` — so a null base is deliberately
// NOT a *not a constructor function type* error. The unit stops one question
// later, at `is-constructor-type`, which is a sentence the port could not even
// ask before the dispatch existed.
class C extends null {
}
