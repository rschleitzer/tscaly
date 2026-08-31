#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# battery-selftest.sh — does battery-lib.sh still drive a battery?
#
# ★★★ A LIBRARY NOBODY RUNS IS NOT A LIBRARY, and this is the cheapest possible proof
# that the extraction did not change what a battery measures: it re-runs slice 108's g04
# — the call-count short circuit dropped — through the library instead of through the
# copied scaffolding, and the numbers must come out IDENTICAL to what the full battery
# recorded for that row:
#
#     callgate  244 22 4 4 214 545312645 -> 244 0 4 4 236 792422449
#     relgate   890 840 34 16 1911582089 -> 881 834 31 16 2175649970
#     stopgate  ...1551 7397 1 -> ...1541 7374 1
#
# ★ It runs in about 80 s (baseline plus one row) and needs a stage-1 run.sh tree. Run it
# after any edit to battery-lib.sh, and read the two gate lines against the numbers above
# rather than against their colour.
. "$(dirname "$0")/battery-lib.sh"
PINFILES="$FIX/callres_arity_ok.ts $FIX/callres_untyped.ts"
battery_init "$@"
baseline
python3 - "$PATCHDIR" <<'MK'
import os, sys
open(os.path.join(sys.argv[1],'s01.py'),'w').write(
"import sys\n"
"old = '''        if num_call_signatures <> 0\\n            return false'''\n"
"new = '''        if false\\n            return false'''\n"
"path = sys.argv[1]\ns = open(path).read()\n"
"assert s.count(old) == 1\n"
"open(path,'w').write(s.replace(old,new))\n")
MK
control "s01 SMOKE — the call-count short circuit dropped" $CHECKER "$PATCHDIR/s01.py"
