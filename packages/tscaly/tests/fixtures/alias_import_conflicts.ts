// Slice 110: checkAliasSymbol's excludedMeanings — an import whose target's
// meaning collides with a local declaration of the same name (TS2440), and the
// export specifier's own message (TS2484).
import { collide } from "./m"
const collide = 1

import { tcollide } from "./m2"
type tcollide = number

const local = 1
export { local }
export { local as duplicate }
export const duplicate = 2
