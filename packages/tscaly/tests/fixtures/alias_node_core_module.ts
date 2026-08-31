// Slice 110: getCannotResolveModuleNameErrorForSpecificModule — a node core
// module name gets TS2591 rather than TS2307, and the `node:` prefix is part of
// the table.
export {}
import fs from "fs"
import { join } from "path/posix"
import sqlite from "node:sqlite"
import notcore from "fsx"
