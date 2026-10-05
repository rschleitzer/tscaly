#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice99.sh — the slice-99 battery: THE OBJECT LITERAL.
#
# ★★★ THE ROW THIS SLICE CLOSES IS THE LARGEST ON THE WORK LIST THAT IS NOT THE
# GLOBALS TABLE, and it had been named by slices 96, 97 and 98 without moving by a
# unit. `check-object-literal 211` was 222 events over 149 units at stage 1 and
# 6 285 events over 2 345 units at stage 2. What removes it is the property-
# assignment family, the anonymous type it builds, the contextual-type stack down
# to the point where an ANSWER needs a chapter, and checkGrammarObjectLiteral
# Expression — which is where this chapter's own diagnostics come from.
#
# ★★★ THE TWELFTH INSTRUMENT, AND ITS ARGUMENT IS THAT THE PRODUCT IS FLATTENED BY
# THE PRINTER. An object literal's type is ANONYMOUS: it has no name, so
# `type_to_string` would render its MEMBERS — and this port's printer answers only
# the keyword arms, so it renders NOTHING and every row of the pin prints `?`.
# Three of the four things this chapter can get wrong therefore have no artifact at
# all: the property symbol's flags, the type's OBJECT FLAGS and its IDENTITY.
# `tscaly_types --objlits` prints `O <pos> <typeid> <objectflags> <propcount> <arm>
# <name>` per object-literal type BUILT.
#
# ★★★ THE `?` COLUMN IS A CONSTANT TODAY AND IT IS PRINTED ANYWAY, which is the
# opposite of this file's usual rule and is said here rather than left to be
# discovered: it reads `?` on all 147 rows because the printer cannot name an
# anonymous type. What moves it is an arm that answers a type of a DIFFERENT KIND —
# an error type, a keyword type, the input — and g16 is the row that does.
#
# ★★★ THE HAND COUNT THAT LICENSES THE NUMBERS BELOW: `--objlits` over the 1 425
# units of this tree reads **147 rows — 138 arm 0 and 9 arm 3** (the expando bail),
# against **222 stop events over 149 units** at the tag this slice removed. The two
# numbers do not match and are not supposed to: an arrival is not an answer, and the
# difference went to the four walls this chapter opens rather than to nothing.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice99.sh 2>&1 | tee /tmp/battery99.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Seven files: the ordinary member
# loop, the grammar check, the contextual type, the destructuring side, the
# accessors, the four walls, and the two arms that need a JAVASCRIPT file.
PINFILES="
$FIX/objlit_basic.ts
$FIX/objlit_grammar.ts
$FIX/objlit_contextual.ts
$FIX/objlit_destructuring.ts
$FIX/objlit_accessors.ts
$FIX/objlit_stops.ts
$FIX/objlit_expando.js
"
# ★★★ EVERY DUMPER CALL BELOW RUNS UNDER A TIME LIMIT, for slice 95's reason:
# breaking one bit of a printer can remove the BASE CASE of its own recursion, and
# a process that grows until the machine does is a verdict a battery cannot produce
# without one. `perl -e 'alarm N; exec @ARGV'` is on every box this repo builds on
# and kills at N seconds with rc 142; timeout(1) is not on macOS.
#
# ★★ THE LIMIT IS PART OF THE MEASUREMENT: a killed call writes nothing, so the pin
# and the gate both MOVE, which is the honest verdict for a patch that makes the
# port not terminate.
LIMIT=${LIMIT:-3}
run_limited() { perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$@"; }

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl99)

PATCHED_FILES=""
cleanup() {
  local f i=0
  for f in $PATCHED_FILES; do
    [ -f "$WORK/orig.$i" ] && cp "$WORK/orig.$i" "$f"
    i=$((i+1))
  done
  [ -n "$PATCHED_FILES" ] && red "INTERRUPTED — $PATCHED_FILES restored from the row that was running."
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

build_bins() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

diags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE OBJPIN — slice 99's TWELFTH instrument; the argument is in ObjLitEvent's
# own header. `O <pos> <typeid> <objectflags> <propcount> <arm> <name>` per object
# literal TYPE this chapter built, in the order the check reached them.
objpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --objlits "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE MEMBER PIN — slice 86's instrument, run beside this slice's own because
# THREE ROWS OF THE FIRST RUN CAME BACK UNGATED AND WERE NOT HOLES: `R <flags>
# <props> <sigs> <indexinfos>` per resolved type and `P <name> <flags> <checkflags>
# <decls>` per property of it. An object literal's TYPE is what this chapter builds
# and the OBJPIN counts the LOOP — so a member dropped between the loop and the
# type, a property symbol minted with the wrong flags, and a readonly bit that
# never arrives are all invisible to the pin written for this slice and visible
# here. **A new instrument does not replace the old ones; it is asked beside them.**
mempin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --members "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS OBJGATE, beside the pin for slice 92's h08/h11/h25 reason:
# a fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape. It reads 147 against the seven
# fixtures' 22, so the corpus is a live half of every row below and not a constant.
#
# ★ The units are dispatched in PARALLEL and each writes its own file, then the
# files are concatenated in a fixed order. A shared pipe would interleave and the
# checksum would move on its own — an instrument that disagrees with itself is
# worse than none.
#
# ★★ IT IS FIVE NUMBERS AND A CHECKSUM, so five breakages are told apart without a
# diff: a chapter that stops building moves the ROW count; the EXPANDO bail has its
# own arm and moves ARM3 alone; a member added or dropped moves the total PROPERTY
# count while the row count stands; the JS arm moves the JSLITERAL count; and a
# wrong type identity, a wrong object-flag or a wrong position moves only the
# CHECKSUM.
#
# ★ NUL-DELIMITED SINCE SLICE 101, AND THE FIX IS NOT COSMETIC: `xargs` splits on
# WHITESPACE, the stage-2 corpus holds one unit whose name contains a space, and
# from it onward the `-n 2` pairing shifts by one — which redirects the dumper's
# stdout INTO A CORPUS FILE. Invisible at stage 1, where no unit path has a space.
# See §3.5eu finding nine.
objgate() {
  local i=0 u
  rm -rf "$WORK/oout" "$WORK/opairs"; mkdir -p "$WORK/oout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/oout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/opairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --objlits "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/opairs"
  find "$WORK/oout" -type f -print0 | xargs -0 cat > "$WORK/obj.all"
  local n a3 props js
  n=$(grep -c '^O ' "$WORK/obj.all")
  a3=$(grep '^O ' "$WORK/obj.all" | awk '$6==3' | wc -l | tr -d ' ')
  props=$(grep '^O ' "$WORK/obj.all" | awk '{s+=$5} END {print s+0}')
  js=$(grep '^O ' "$WORK/obj.all" | awk 'int($4/4096)%2==1' | wc -l | tr -d ' ')
  echo "$n $a3 $props $js $(cksum < "$WORK/obj.all" | cut -d' ' -f1)"
}

# ★★ THE WHOLE-CORPUS MEMGATE, for the objgate's reason and with the same shape.
# Three numbers and a checksum: resolved TYPES, their PROPERTIES, and the sum of
# the property CHECK FLAGS — which is the column `as const` moves and nothing else
# in this battery does.
memgate() {
  local i=0 u
  rm -rf "$WORK/mout" "$WORK/mpairs"; mkdir -p "$WORK/mout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/mout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/mpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --members "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/mpairs"
  find "$WORK/mout" -type f -print0 | xargs -0 cat > "$WORK/mem.all"
  local r pr cf
  r=$(grep -c '^R ' "$WORK/mem.all")
  pr=$(grep -c '^P ' "$WORK/mem.all")
  cf=$(grep '^P ' "$WORK/mem.all" | awk '{s+=$4} END {print s+0}')
  echo "$r $pr $cf $(cksum < "$WORK/mem.all" | cut -d' ' -f1)"
}

stopgate() {   # writes "matched units speaking events other" to stdout
  BIN=$WORK/tscaly_types packages/tscaly/tests/stops.sh > "$WORK/stops.out" 2>&1
  local m u s e o
  m=$(sed -n 's/^  agreeing with the work list  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  u=$(sed -n 's/^  units compared  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  s=$(sed -n 's/^  units with a stop  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  e=$(sed -n 's/^  stop events  *\([0-9]*\)$/\1/p' "$WORK/stops.out")
  o=$(sed -n 's/^  parse\/bind stop  *\([0-9]*\).*$/\1/p' "$WORK/stops.out")
  echo "$m $u $s $e $o"
}

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; OBJ_BASE=""; MEM_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — nine instruments"
  if ! build_bins; then
    red "the unpatched tree did not build — every row below would be measuring that."
    sed 's/^/    /' "$WORK/build.log"
    exit 2
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/base.diag" 2>&1
  local rc=$?
  DIAG_BASE=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/base.diag")
  DIAG_LINES=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/base.diag")
  DIAG_DIAGS=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/base.diag")
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  diags_of > "$WORK/base.diags"
  stops_of > "$WORK/base.stops"
  objpin_of > "$WORK/base.obj"
  mempin_of > "$WORK/base.mem"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  OBJ_BASE=$(objgate)
  MEM_BASE=$(memgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the OBJPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.obj"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             objgate   (rows arm3 props jsliteral checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $OBJ_BASE"
  echo "             memgate   (types props checkflags checksum) = $MEM_BASE"
}

control() {   # $1 = label, $2 = files, $3 = patch
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_FILES="$files"
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  echo "  patched $files"
  if ! build_bins; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""; return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags stop
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
  diags_of > "$WORK/ctl.diags"
  stops_of > "$WORK/ctl.stops"
  objpin_of > "$WORK/ctl.obj"
  mempin_of > "$WORK/ctl.mem"
  stop=$(stopgate)
  local obj_g mem_g
  obj_g=$(objgate)
  mem_g=$(memgate)
  local restored=1
  i=0
  for f in $files; do
    cp "$WORK/orig.$i" "$f"
    cmp -s "$WORK/orig.$i" "$f" || restored=0
    i=$((i+1))
  done
  if [ "$restored" != 1 ]; then
    red "the source did NOT come back — every number below is suspect."
    return 1
  fi
  PATCHED_FILES=""
  echo "  RESTORE VERIFIED   $files byte-identical"
  echo
  local moved=0
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
    moved=1
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.diags" "$WORK/ctl.diags"; then
    echo "  diagpin   unmoved — all seven pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all seven fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all seven fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.obj" "$WORK/ctl.obj"; then
    echo "  objpin    unmoved — all seven fixtures build the same types, in the same order."
  else
    green "objpin    RED"
    diff "$WORK/base.obj" "$WORK/ctl.obj" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if cmp -s "$WORK/base.mem" "$WORK/ctl.mem"; then
    echo "  mempin    unmoved — all seven fixtures resolve the same members."
  else
    green "mempin    RED"
    diff "$WORK/base.mem" "$WORK/ctl.mem" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$obj_g" = "$OBJ_BASE" ]; then
    echo "  objgate   unmoved — $obj_g"
  else
    green "objgate   MOVED   $OBJ_BASE -> $obj_g   (rows arm3 props jsliteral checksum)"
    moved=1
  fi
  if [ "$mem_g" = "$MEM_BASE" ]; then
    echo "  memgate   unmoved — $mem_g"
  else
    green "memgate   MOVED   $MEM_BASE -> $mem_g   (types props checkflags checksum)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all nine, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL NINE AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

python3 - "$PATCHDIR" <<'MKPATCHES'
import os, sys
D = sys.argv[1]
os.makedirs(D, exist_ok=True)

P = {}

P['g01'] = ('''# THE PREMISE — checkExpressionWorker's ObjectLiteralExpression arm reverted to
# the stop it was until this slice. PREDICTION: everything RED, and the two gates
# moving by the numbers the hand count named — 147 objpin rows gone, the tag back
# on 149 units of the corpus.''',
'''old = """        if k = KindObjectLiteralExpression
            return this.check_object_literal(node, check_mode)"""
new = """        if k = KindObjectLiteralExpression
        {
            this.record_unported("check-object-literal", k)
            return null
        }"""''')

P['g02'] = ('''# THE EXPANDO BAIL removed, so a literal with no properties and a filled export
# table falls into the member loop and builds an EMPTY type. PREDICTION: the
# objgate's ARM3 count goes to zero and the row count stands — the bail is replaced
# by a tail row, not by nothing — and only the .js pin file moves.''',
'''old = """                if SymbolTable.length(Symbol.exports_of(s)) <> 0
                {"""
new = """                if false
                {"""''')

P['g03'] = ('''# THE GRAMMAR CHECK not called. PREDICTION: diagcheck UNGATED and the DIAGPIN RED
# — this is the row that separates the two, because diagcheck's relation is a
# SUBSEQUENCE and printing FEWER lines is a subsequence of anything. A battery
# reading only the whole-corpus gate would call the whole grammar half green.''',
'''old = """        this.check_grammar_object_literal_expression(node, in_destructuring_pattern)"""
new = """        if false
            this.check_grammar_object_literal_expression(node, in_destructuring_pattern)"""''')

P['g04'] = ('''# THE `{ a = 1 }` SPAN — the report goes to the NAME instead of to the last child
# before the initializer, which is the `=` token. PREDICTION: diagcheck RED on ONE
# unit of the corpus and the diagpin RED on objlit_grammar.ts, at a span two bytes
# early. This is the defect this slice actually shipped and had to be told about by
# the suite; the row exists so that the reasoning which produced it stays refuted.''',
'''old = """                        this.grammar_error_on_first_token(Checker.last_child_before(prop, oai), Diag"""
new = """                        this.grammar_error_on_first_token(name, Diag"""''')

P['g05'] = ('''# THE `seen` MAP never remembers a name, so no duplicate is ever the second one.
# PREDICTION: diagcheck UNGATED (fewer lines is a subsequence) and the diagpin RED
# on objlit_grammar.ts, which loses every duplicate-name report at once. The row
# that says the four duplicate arms are ONE mechanism.''',
'''old = """                seen.add(&SeenPropertyName^host(name_data, name_len, current_kind) as ref[SeenPropertyName])"""
new = """                continue"""''')

P['g06'] = ('''# THE `async` ESCAPE of the modifier walk dropped, so `async m() {}` in an object
# literal is reported as an illegal modifier. PREDICTION: diagcheck RED — this is
# the direction the subsequence relation CAN see, an INVENTED line — and it is the
# one conjunct that differs between the CanHaveModifiers fork and the
# CanHaveIllegalModifiers one.''',
'''old = """        var async_allowed false
        if k = KindMethodDeclaration
            set async_allowed: true"""
new = """        var async_allowed false"""''')

P['g07'] = ('''# THE DESTRUCTURING SKIP of the duplicate check dropped, so `({ a, a } = o)` is
# reported. PREDICTION: diagcheck RED on the corpus — an invented line — and the
# destructuring pin file is the only fixture that can show it.''',
'''old = """            if in_destructuring
                continue
            var name_data null as pointer[char]"""
new = """            var name_data null as pointer[char]"""''')

P['g08'] = ('''# THE CONTEXTUAL STACK never pushed, so findContextualNode can never hit and a
# nested literal recomputes its parent's contextual type instead of reading it.
# PREDICTION: the objpin RED on objlit_contextual.ts and the objgate's CHECKSUM
# moved — the answers are structurally the same and their IDENTITIES are not, which
# is what every later comparison in this checker is made of.''',
'''old = """        this.push_cached_contextual_type(node)
        set st.contextual_type:"""
new = """        this.push_contextual_type(node, null, true)
        set st.contextual_type:"""''')

P['g09'] = ('''# THE CACHE LOOKUP of getContextualType removed, so a node on the stack is asked
# again from its parent. PREDICTION: the objpin RED, and it is NOT g08 twice: g08
# stores nothing and this refuses to read what is stored, so the two rows together
# say the stack has a writer and a reader that fail differently.''',
'''old = """        let index this.find_contextual_node(node, context_flags = ContextFlagsNone)
        if index >= 0
            return this.contextual_type_at(index)"""
new = """        let index 0 - 1
        if index >= 0
            return this.contextual_type_at(index)"""''')

P['g10'] = ('''# THE ANNOTATION ARM of getContextualTypeForObjectLiteralElement dropped, so a
# member with its own `: T` falls through to the outer literal's contextual type.
# PREDICTION: the stoppin RED on objlit_contextual.ts — the member now asks a
# question whose answer needs the members of a contextual type — with the objpin
# moving with it.''',
'''old = """        let tn AstNode.type_of(element)
        if tn <> null
        {
            if Binder.is_object_literal_method(element) = false
                return this.get_type_from_type_node(tn as ref[AstNode])
        }
        let object_literal AstNode.parent_node_of(element)"""
new = """        let object_literal AstNode.parent_node_of(element)"""''')

P['g11'] = ('''# THE ANNOTATION ARM of getContextualTypeForVariableLikeDeclaration dropped, so
# `const x: T = { … }` has NO contextual type. PREDICTION: the stoppin and the
# objpin both RED on objlit_contextual.ts — and in the direction that LOOKS like
# progress: the annotated literals stop reaching the contextual-members wall and
# start building types instead. A gate counting rows alone would read this as more
# of the corpus answered.''',
'''old = """        let type_node AstNode.type_of(declaration)
        if type_node <> null
            return this.get_type_from_type_node(type_node as ref[AstNode])"""
new = """        let type_node AstNode.type_of(declaration)
        if false
            return this.get_type_from_type_node(type_node as ref[AstNode])"""''')

P['g12'] = ('''# THE COMPUTED-NAME PRE-PASS removed, so the report lands on whichever computed
# name the MEMBER LOOP reaches first rather than on the first one in the literal.
# PREDICTION: the two are the same node in every fixture here, so this is ungated
# unless a SPREAD precedes a computed name — which objlit_stops.ts does not have.
# The reference's own comment says why the pre-pass exists; this row measures
# whether the corpus can tell.''',
'''old = """            if AstNode.kind_of(nm as ref[AstNode]) = KindComputedPropertyName
            {
                this.check_computed_property_name(nm as ref[AstNode])
                this.pop_contextual_type()
                return null
            }"""
new = """            if false
            {
                this.check_computed_property_name(nm as ref[AstNode])
                this.pop_contextual_type()
                return null
            }"""''')

P['g13'] = ('''# THE ACCESSOR ARM stops adding its symbol to the properties table. PREDICTION:
# the objgate's PROPERTY count falls at an unchanged ROW count, which is exactly the
# column that separates a chapter that stopped from a member that vanished — and
# the objpin RED on objlit_accessors.ts alone.''',
'''old = """                this.check_node_deferred(member_decl)
                SymbolTable.set_entry(host, st.properties_table as ref[SymbolTable], Symbol.name_data_of(member), Symbol.name_len_of(member), member)
                st.properties_array.add(member)
                continue
            }
            if mk = KindSetAccessor"""
new = """                this.check_node_deferred(member_decl)
                continue
            }
            if mk = KindSetAccessor"""''')

P['g14'] = ('''# THE PROPERTY SYMBOL minted WITHOUT its member's flags, so an optional or a
# readonly member arrives as a plain property. PREDICTION: ungated on every
# instrument here — the flags of a property symbol are not printed by any artifact
# this suite compares, and the member log prints the SYMBOL's flags only for a type
# whose members are resolved through set_structured_type_members, which these are.
# A row that is a HOLE if it comes back green and a measurement if it does not.''',
'''old = """            let prop this.new_symbol_ex(SymbolFlagsProperty | Symbol.flags_of(member), Symbol.name_data_of(member), Symbol.name_len_of(member), st.check_flags)"""
new = """            let prop this.new_symbol_ex(SymbolFlagsProperty, Symbol.name_data_of(member), Symbol.name_len_of(member), st.check_flags)"""''')

P['g15'] = ('''# THE CONST CONTEXT's first term (`as const` on the parent) dropped, so a frozen
# literal widens its members and loses ObjectFlagsReadonly on every property.
# PREDICTION: the objpin RED on objlit_contextual.ts through the CHECK FLAGS, which
# reach no column — so the honest expectation is that only the members instrument
# would see it, and this row is here to find out whether the objgate's checksum does
# too.''',
'''old = """        if Checker.is_const_assertion(parent)
            return true
        if this.is_valid_const_assertion_argument(node)"""
new = """        if this.is_valid_const_assertion_argument(node)"""''')

P['g16'] = ('''# THE ANSWER REPLACED BY THE ERROR TYPE — checkObjectLiteral builds its type and
# then answers something else. PREDICTION: the objpin's rows STAND (the type is
# still built and still logged) and the whole rest of the check moves, which is the
# row that says a pin at a construction site is not a pin on the answer. It is also
# the only row that can move the `?` column, from the other side.''',
'''old = """        this.create_object_literal_type(node, st, 0)
    }"""
new = """        this.create_object_literal_type(node, st, 0)
        error_type
    }"""''')

P['g17'] = ('''# THE MEMBERS not handed to the anonymous type, so every object literal answers a
# type with an empty table. PREDICTION: the objgate's ROW and PROPERTY counts both
# STAND — the properties array is what the pin counts and it is still filled — and
# the CHECKSUM moves through the type ids alone. The row that says the pin's
# property column is about the LOOP and the members instrument is about the TYPE.''',
'''old = """        let made this.new_anonymous_type(AstNode.symbol_of(node), st.properties_table, null, null, null)"""
new = """        let made this.new_anonymous_type(AstNode.symbol_of(node), null, null, null, null)"""''')

P['g18'] = ('''# THE JSLITERAL BIT never set. PREDICTION: the objgate's JSLITERAL count goes to
# zero at every other column unchanged, and only the .js pin file moves — the row
# the seventh fixture exists for, and the one a TypeScript-only corpus would have
# called green.''',
'''old = """        if st.contextual_type = null
        {
            if Parser.is_in_js_file(node)
            {
                if Checker.is_in_json_file(node) = false
                    set result.object_flags: result.object_flags | ObjectFlagsJSLiteral
            }
        }"""
new = """        if false
        {
            if Parser.is_in_js_file(node)
            {
                if Checker.is_in_json_file(node) = false
                    set result.object_flags: result.object_flags | ObjectFlagsJSLiteral
            }
        }"""''')

P['g19'] = ('''# THE SPREAD STOP removed, so a spread member is skipped and the literal answers a
# type over the members AROUND it. PREDICTION: the objgate's ROW count goes UP —
# every spread literal in the corpus starts answering — and it is the shape this
# whole file is organized against: a well-formed WRONG type, with no stop and no
# diagnostic anywhere.''',
'''old = """                this.record_unported("get-spread-type", mk)
                this.pop_contextual_type()
                return null"""
new = """                continue"""''')

P['g20'] = ('''# THE PROPAGATION TERM dropped. PREDICTION: UNGATED with a containment proof —
# ObjectFlagsPropagatingFlags is three bits and none of them can reach a member type
# under this harness's options: ContainsWideningType is not set at all
# (createWideningType returns the non-widening type under strictNullChecks),
# ContainsObjectOrArrayLiteral is OR-ed in unconditionally one line later, and
# NonInferrableType needs anyFunctionType, which this port does not mint.''',
'''old = """            set st.object_flags: st.object_flags | (ty.object_flags & ObjectFlagsPropagatingFlags)"""
new = """            set st.object_flags: st.object_flags"""''')

for k, (doc, body) in P.items():
    with open(os.path.join(D, k + '.py'), 'w') as f:
        f.write(doc + '\n')
        f.write('''import sys
''')
        f.write(body + '\n')
        f.write('''
path = sys.argv[1]
s = open(path).read()
if s.count(old) != 1:
    sys.stderr.write("anchor count %d for %s\\n" % (s.count(old), path))
    sys.exit(1)
open(path, 'w').write(s.replace(old, new))
''')
MKPATCHES

baseline

control "g01 THE PREMISE (checkExpressionWorker's object-literal arm) reverted to its stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the EXPANDO BAIL removed" $CHECKER "$PATCHDIR/g02.py"
control "g03 the GRAMMAR CHECK not called" $CHECKER "$PATCHDIR/g03.py"
control "g04 the { a = 1 } report moved to the NAME instead of the = token" $CHECKER "$PATCHDIR/g04.py"
control "g05 the seen MAP never remembers a name" $CHECKER "$PATCHDIR/g05.py"
control "g06 the async ESCAPE of the modifier walk dropped" $CHECKER "$PATCHDIR/g06.py"
control "g07 the DESTRUCTURING SKIP of the duplicate check dropped" $CHECKER "$PATCHDIR/g07.py"
control "g08 the CONTEXTUAL STACK pushed with no type" $CHECKER "$PATCHDIR/g08.py"
control "g09 the CACHE LOOKUP of getContextualType removed" $CHECKER "$PATCHDIR/g09.py"
control "g10 the ANNOTATION ARM of getContextualTypeForObjectLiteralElement dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the ANNOTATION ARM of getContextualTypeForVariableLikeDeclaration dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 the COMPUTED-NAME PRE-PASS removed" $CHECKER "$PATCHDIR/g12.py"
control "g13 the ACCESSOR ARM stops adding its symbol to the table" $CHECKER "$PATCHDIR/g13.py"
control "g14 the PROPERTY SYMBOL minted without its member's flags" $CHECKER "$PATCHDIR/g14.py"
control "g15 isConstContext's as-const term dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 checkObjectLiteral answers the ERROR TYPE after building its own" $CHECKER "$PATCHDIR/g16.py"
control "g17 the MEMBERS not handed to the anonymous type" $CHECKER "$PATCHDIR/g17.py"
control "g18 the JSLITERAL bit never set" $CHECKER "$PATCHDIR/g18.py"
control "g19 the SPREAD STOP removed" $CHECKER "$PATCHDIR/g19.py"
control "g20 the PROPAGATION term dropped" $CHECKER "$PATCHDIR/g20.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
