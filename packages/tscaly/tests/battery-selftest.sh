#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# battery-selftest.sh — does battery-lib.sh still drive a battery?
#
# ★★★ A LIBRARY NOBODY RUNS IS NOT A LIBRARY, and this is the cheapest possible proof
# that the extraction did not change what a battery measures: it re-runs slice 108's g04
# — the call-count short circuit dropped — through the library instead of through the
# copied scaffolding.
#
# ★★★ WHAT IS PINNED IS THE DELTA AND NOT THE ABSOLUTE, and slice 109 is why. Its first
# version listed the absolute numbers slice 108's full battery recorded, and one slice
# later every one of them was stale: the checker no longer stops where it did (1551
# speaking units became 1416) and the corpus grew by five fixtures. **An absolute pin on
# a moving tree fails for the wrong reason, which is the failure mode that teaches a
# reader to ignore a red.** The DELTA is a property of the patch and survives:
#
#     callgate  resolved -22 (to 0), couldnotanswer +22, rows unchanged
#     relgate   rows -9, related -6, couldnotanswer -3
#     stopgate  matched -10, speaking -10, events -23
#     typegate  checksum MOVES, the three counts do not   (slice 109's instrument)
#
# ★ Measured on slice 109's tree: callgate 244 22 4 4 214 -> 244 0 4 4 236, relgate 898
# 846 36 16 -> 889 840 33 16, stopgate 1570 1570 1416 7271 1 -> 1560 1570 1406 7248 1,
# typegate 147 1339 1555 <cksum> -> 147 1339 1555 <other cksum>. Read the DIFFERENCES
# against the list above; the checksums are tree-dependent and are never pinned here.
#
# ★ It runs in about 80 s (baseline plus one row) and needs a stage-1 run.sh tree. Run it
# after any edit to battery-lib.sh, and read the gate lines rather than their colour.
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
