// Slice 110: every shape that asks the module resolver, against a stub program
// that resolves nothing — so each specifier reports TS2307 and each alias comes to
// unknownSymbol, which getSymbolFlags answers as SymbolFlagsAll.
export {}
import d from "./nope"
import * as ns from "./nope2"
import { a, b as c } from "./nope3"
import "./side-effect-only"
import ie = require("./nope4")
export { x } from "./nope5"
export * from "./nope6"
export * as reexported from "./nope7"
