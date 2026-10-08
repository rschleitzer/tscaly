#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice100.sh — the slice-100 battery: THE FUNCTION EXPRESSION, THE
# ARROW FUNCTION AND THE OBJECT-LITERAL METHOD.
#
# ★★★ THE ROW THIS SLICE CLOSES IS THE ONE SLICE 99 CREATED, and it is three rows
# rather than one: `check-function-expression-or-object-literal-method` stood at
# 1 085 units (arrow), 573 (function expression) and 234 (method) at stage 2 —
# together the largest wall on the work list that is neither the globals table nor
# the assignability relation. What removes it is the entry function, the
# contextual half (getContextualSignature, the two parameter-assignment arms), the
# grammar half including checkGrammarArrowFunction, and the DEFERRED half, which
# is where the product is.
#
# ★★★ THE DEFERRED HALF ONLY EXISTS BECAUSE OF ONE OTHER LINE, AND THAT LINE IS
# g04. `check_source_file` returned as soon as any statement had reported, and
# `check_deferred_nodes` sat below that return — so on 1 494 units of 1 509 the
# drain never RAN. Slice 60 wrote that down and named the day: *lifting that early
# return for real is a slice of its own, and the reference has no such exit.* It
# had to be lifted with THIS chapter, because the body of every function
# expression and arrow function in the corpus is walked by the drain or by nothing.
#
# ★★★ THE THIRTEENTH INSTRUMENT, AND ITS ARGUMENT IS THAT THE DECISION IS
# INVISIBLE EVERYWHERE ELSE. The type this chapter answers is the SYMBOL's, which
# slice 86's `--members` already prints; its diagnostics are diagcheck's; its body
# walk is the stop log's. What none of the three can see is whether the function
# was judged CONTEXT SENSITIVE, whether a contextual signature was found, and
# which parameter-assignment arm ran — and a wrong port of getContextualSignature
# moves those three and nothing else. `tscaly_types --functions` prints
# `F <pos> <kind> <sensitive> <ctxsig> <arm> <typeid>`.
#
# ★★★ AND THE PIN HAD TO BE MOVED ONCE BEFORE IT COULD SAY ANYTHING. Its first
# draft wrote a row only where the chapter ANSWERED — ObjLitEvent's rule — and the
# `ctxsig` column then read 0 on every row of every fixture, because a contextual
# signature that IS found sends the function to getReturnTypeFromBody, which
# stops. It now writes at the DECISION and carries `typeid` 0 for a row that did
# not answer. **A pin whose most interesting column is a constant is slice 99's
# finding seven; the difference here is that it had a fix.**
#
# ★★★ THE HAND COUNT THAT LICENSES THE NUMBERS BELOW: `--functions` over the eight
# pin files reads **63 rows** across all three kinds, both values of `sensitive`,
# both of `ctxsig` and all four arms; the whole-corpus FNGATE reads **229 rows over
# 1 439 units**, of which 65 are context sensitive, 17 found a contextual signature
# and 138 reached a type. Against them stand 87 + 47 + 40 stop events at the three
# tags this slice removed — arrival is not an answer, and the difference went to
# the walls this chapter opens rather than to nothing.
#
# ★★★ THE BATTERY WAS RUN TWICE AND THE SECOND RUN IS THE ONE OF RECORD. The
# first had TWELVE ungated rows and EIGHT of them were FIXTURE weaknesses rather
# than findings — a control on the binary arm written against `1 + 1`, which
# answers false whether or not the arm reads the operator token; a union
# contextual type written through a type ALIAS, which stops one chapter out; an
# `isAritySmaller` `this` decrement probed with `this` on the CONTEXTUAL signature
# rather than on the function. **A control that cannot fire measures the fixture,
# not the port**, and the tell is a whole COLUMN of the pin that no row moves.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice100.sh 2>&1 | tee /tmp/battery100.log
#
# ★★ A ROW FILTER (slice 100). `controls-slice100.sh g17 g19 g20` runs the
# baseline and then only the named rows. It exists because twelve rows of the
# first run came back UNGATED and eight of them were FIXTURE weaknesses rather
# than findings — and re-running the whole battery to re-ask eight questions is
# forty minutes for eight answers. ★The baseline is NEVER skipped: every verdict
# below is a comparison against it.
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). Eight files: the ordinary shape, the
# contextual half, the grammar half, the deferred body walk, the sensitivity
# predicate, the four walls, the arrow-function grammar check (which needs the
# `.mts` extension — the extension IS the input), and the object literal's
# accessors, which is the arm slice 99 deferred and this slice gave a handler.
PINFILES="
$FIX/fnexpr_basic.ts
$FIX/fnexpr_contextual.ts
$FIX/fnexpr_grammar.ts
$FIX/fnexpr_deferred.ts
$FIX/fnexpr_sensitive.ts
$FIX/fnexpr_stops.ts
$FIX/fnexpr_arrow_grammar.mts
$FIX/objlit_accessors.ts
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

WORK=$(mktemp -d -t tscaly-ctl100)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.1/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.1/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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

# ★★★ THE FNPIN — slice 100's THIRTEENTH instrument; the argument is in FnEvent's
# own header. `F <pos> <kind> <sensitive> <ctxsig> <arm> <typeid>` per function
# expression, arrow function or object-literal method this chapter DECIDED about,
# in the order the check reached them.
fnpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --functions "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE OBJPIN — slice 99's instrument, run beside this slice's own for the
# reason slice 99 gave when it added slice 86's: **a new instrument does not
# replace the old ones; it is asked beside them.** It is here specifically because
# this slice gives checkObjectLiteral's METHOD arm an answer where it had a stop,
# and the object literal's own type is what that arm feeds.
objpin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --objlits "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE MEMBER PIN — slice 86's. `R <flags> <props> <sigs> <indexinfos>` per
# resolved type, `P …` per property and `G …` per SIGNATURE. It is the only
# instrument here that can see a signature's PARAMETER COUNT and minimum argument
# count, which is what assignContextualParameterTypes writes into.
mempin_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$(run_limited "$WORK/tscaly_types" --members "$f" 2>/dev/null | tr '\n' '|')"
  done
}

# ★★★ THE WHOLE-CORPUS FNGATE, beside the pin for slice 92's h08/h11/h25 reason: a
# fixture is written around the arm its author is thinking of, and the shape that
# distinguishes an arm is usually not that shape. It reads 512 against the eight
# fixtures' 31, so the corpus is a live half of every row below and not a constant.
#
# ★★ IT IS FIVE NUMBERS AND A CHECKSUM, so five breakages are told apart without a
# diff: a chapter that stops deciding moves the ROW count; the sensitivity
# predicate moves SENSITIVE alone; getContextualSignature moves CTXSIG; the two
# assignment arms move ANSWERED (a row that reached a type); and a wrong identity,
# a wrong arm or a wrong position moves only the CHECKSUM.
#
# ★ NUL-DELIMITED SINCE SLICE 101, AND THE FIX IS NOT COSMETIC: `xargs` splits on
# WHITESPACE, the stage-2 corpus holds one unit whose name contains a space, and
# from it onward the `-n 2` pairing shifts by one — which redirects the dumper's
# stdout INTO A CORPUS FILE. Invisible at stage 1, where no unit path has a space.
# See §3.5eu finding nine.
fngate() {
  local i=0 u
  rm -rf "$WORK/fout" "$WORK/fpairs"; mkdir -p "$WORK/fout"
  while IFS= read -r u; do
    printf '%s\0%s\0' "$u" "$(printf '%s/fout/%06d' "$WORK" "$i")"
    i=$((i+1))
  done < "$WORK/units.txt" > "$WORK/fpairs"
  LIMIT=$LIMIT xargs -0 -P 8 -n 2 sh -c 'perl -e "alarm $LIMIT; exec @ARGV" "$0" --functions "$1" > "$2" 2>/dev/null' "$WORK/tscaly_types" < "$WORK/fpairs"
  find "$WORK/fout" -type f -print0 | xargs -0 cat > "$WORK/fn.all"
  local n se cs an
  n=$(grep -c '^F ' "$WORK/fn.all")
  se=$(grep '^F ' "$WORK/fn.all" | awk '$4==1' | wc -l | tr -d ' ')
  cs=$(grep '^F ' "$WORK/fn.all" | awk '$5==1' | wc -l | tr -d ' ')
  an=$(grep '^F ' "$WORK/fn.all" | awk '$7!=0' | wc -l | tr -d ' ')
  echo "$n $se $cs $an $(cksum < "$WORK/fn.all" | cut -d' ' -f1)"
}

# ★★ THE WHOLE-CORPUS MEMGATE, for the fngate's reason and with the same shape.
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""; FN_BASE=""; MEM_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — ten instruments"
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
  fnpin_of > "$WORK/base.fn"
  objpin_of > "$WORK/base.obj"
  mempin_of > "$WORK/base.mem"
  find "$PKG/tests/out/cases" -path '*/units/*' -type f \
       \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.mts' \) \
       | sort > "$WORK/units.txt"
  STOP_BASE=$(stopgate)
  FN_BASE=$(fngate)
  MEM_BASE=$(memgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  the FNPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.fn"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
  echo "             fngate    (rows sensitive ctxsig answered checksum) over $(wc -l < "$WORK/units.txt" | tr -d ' ') units = $FN_BASE"
  echo "             memgate   (types props checkflags checksum) = $MEM_BASE"
}

ONLY="$*"

control() {   # $1 = label, $2 = files, $3 = patch
  if [ -n "$ONLY" ]; then
    case " $ONLY " in
      *" ${1%% *} "*) ;;
      *) return 0 ;;
    esac
  fi
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
  fnpin_of > "$WORK/ctl.fn"
  objpin_of > "$WORK/ctl.obj"
  mempin_of > "$WORK/ctl.mem"
  stop=$(stopgate)
  local fn_g mem_g
  fn_g=$(fngate)
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
    echo "  diagpin   unmoved — all eight pin files answer the same C section."
  else
    green "diagpin   RED"
    diff "$WORK/base.diags" "$WORK/ctl.diags" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  tagpin    unmoved — all eight fixtures answer the same tag."
  else
    green "tagpin    RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.stops" "$WORK/ctl.stops"; then
    echo "  stoppin   unmoved — all eight fixtures log the same stops, in order."
  else
    green "stoppin   RED"
    diff "$WORK/base.stops" "$WORK/ctl.stops" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.fn" "$WORK/ctl.fn"; then
    echo "  fnpin     unmoved — all eight fixtures decide the same way, in the same order."
  else
    green "fnpin     RED"
    diff "$WORK/base.fn" "$WORK/ctl.fn" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if cmp -s "$WORK/base.obj" "$WORK/ctl.obj"; then
    echo "  objpin    unmoved — all eight fixtures build the same object-literal types."
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
    echo "  mempin    unmoved — all eight fixtures resolve the same members."
  else
    green "mempin    RED"
    diff "$WORK/base.mem" "$WORK/ctl.mem" | cut -c1-240 | sed 's/^/    /'
    moved=1
  fi
  if [ "$fn_g" = "$FN_BASE" ]; then
    echo "  fngate    unmoved — $fn_g"
  else
    green "fngate    MOVED   $FN_BASE -> $fn_g   (rows sensitive ctxsig answered checksum)"
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
      echo "  ungated on all ten, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL TEN AND NOTHING MOVED AT ALL."
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

P['g01'] = ('''# THE PREMISE — checkExpressionWorker's FunctionExpression and ArrowFunction arms
# reverted to the stop they were until this slice. PREDICTION: everything RED, the
# fngate falling to the object-literal methods alone, and the tag back on the two
# largest rows of the work list.''',
'''old = """        if k = KindFunctionExpression
            return this.check_function_expression_or_object_literal_method(node, check_mode)
        if k = KindArrowFunction
            return this.check_function_expression_or_object_literal_method(node, check_mode)"""
new = """        if k = KindFunctionExpression
        {
            this.record_unported("check-function-expression-or-object-literal-method", k)
            return null
        }
        if k = KindArrowFunction
        {
            this.record_unported("check-function-expression-or-object-literal-method", k)
            return null
        }"""''')

P['g02'] = ('''# THE OBJECT-LITERAL METHOD arm reverted to its stop. PREDICTION: the fngate's ROW
# count falls by the method rows alone and the two other kinds stand — the row that
# says the third kind reaches this chapter by a different door.''',
'''old = """        if Binder.is_object_literal_method(member_decl)
            return this.check_object_literal_method(member_decl, mk, check_mode)"""
new = """        if Binder.is_object_literal_method(member_decl)
        {
            this.check_grammar_method(member_decl)
            this.record_unported("check-function-expression-or-object-literal-method", mk)
            return null
        }"""''')

P['g03'] = ('''# THE DEFERRAL not made — checkNodeDeferred is not called, so no function-like node
# ever reaches the drain. PREDICTION: the DEFERRED HALF disappears entirely: the
# diagpin loses fnexpr_deferred.ts's whole C section, the stoppin loses every stop
# the body walk produces, and the fngate does NOT move, because the decision half
# runs regardless. The row that separates this chapter's two halves.''',
'''old = """        let k AstNode.kind_of(node)
        this.check_node_deferred(node)
        if k = KindFunctionExpression
            this.check_collisions_for_declaration_name(node, AstNode.name_of(node))"""
new = """        let k AstNode.kind_of(node)
        if k = KindFunctionExpression
            this.check_collisions_for_declaration_name(node, AstNode.name_of(node))"""''')

P['g04'] = ('''# THE EARLY RETURN put back in front of the drain — the line slice 60 named and
# this slice lifted. PREDICTION: the largest single row of this battery. The drain
# runs on 15 units of 1 509 again, so the deferred half of THREE chapters goes
# quiet at once (the function-like one, the type parameter's and the accessor's),
# and both the diagpin and the stopgate move by a large number while the FNGATE
# stands — the decision half is above the return.''',
'''old = """        this.check_source_elements(AstNode.statements_of(file))

        ; ★★★ SLICE 100 LIFTS THE EARLY RETURN THAT STOOD HERE"""
new = """        this.check_source_elements(AstNode.statements_of(file))
        if this.is_unported()
            return

        ; ★★★ SLICE 100 LIFTS THE EARLY RETURN THAT STOOD HERE"""''')

P['g05'] = ('''# THE DRAIN'S FUNCTION-LIKE ARM removed, so a deferred function expression falls
# through the switch. PREDICTION: exactly g03's product with none of its cause —
# the node is still deferred, the list still grows, and nothing happens. The row
# that says a missing arm in this switch is INDISTINGUISHABLE from an arm that
# answers, which is the defect this slice found in slice 99's accessor deferral.''',
'''old = """        if function_like
        {
            this.check_function_expression_or_object_literal_method_deferred(node as ref[AstNode])
            return
        }"""
new = """        if function_like
            return"""''')

P['g06'] = ('''# THE DRAIN'S ACCESSOR ARM removed — the defect this slice REPAIRED, put back.
# Slice 99 deferred an object literal's get/set accessor and this switch had no
# accessor arm, so checkAccessorDeclaration never ran for one. PREDICTION: the
# diagpin RED on objlit_accessors.ts and the stopgate moved, with the FNPIN
# unmoved — the two halves are independent and only running both says so.''',
'''old = """        if accessor
            this.check_accessor_declaration(node as ref[AstNode])"""
new = """        if accessor
            return"""''')

P['g07'] = ('''# checkCollisionsForDeclarationName not called for a function expression.
# PREDICTION: UNGATED ON ALL TEN, WITH A PROOF THAT IS MEASURED AND NOT ARGUED.
# For a function expression the five generated-code collision checks are all this
# call reaches — the two below it need a class or an enum — and every one of the
# five is closed here: three by a language-version guard that ScriptTargetES2025
# passes, one by the module format, and `Object` by its declaration-container
# test. Probed both ways: `const a = function Object() {}`, `function require()`
# and `function Promise()` in a module, and THE REFERENCE REPORTS NOTHING EITHER.
# ★That last half is what makes it a proof rather than a hope.''',
'''old = """        if k = KindFunctionExpression
            this.check_collisions_for_declaration_name(node, AstNode.name_of(node))"""
new = """        if false
            this.check_collisions_for_declaration_name(node, AstNode.name_of(node))"""''')

P['g08'] = ('''# THE GRAMMAR CHECK not called. PREDICTION: the diagpin RED on fnexpr_grammar.ts,
# which loses its whole C section, and diagcheck UNGATED for slice 99 g03's reason
# — printing FEWER lines is a subsequence of anything.''',
'''old = """        let has_grammar_error this.check_grammar_function_like_declaration(node)"""
new = """        let has_grammar_error false"""''')

P['g09'] = ('''# THE GENERATOR CHECK'S KIND GUARD dropped, so an ARROW reaches
# checkGrammarForGenerator. PREDICTION: UNGATED, with a proof — an arrow function
# has no asterisk token, which is checkGrammarForGenerator's own first line, so the
# guard is redundant with the function it guards. If this row is red, the guard is
# load-bearing and this note is wrong.''',
'''old = """        if has_grammar_error = false
        {
            if k = KindFunctionExpression
                this.check_grammar_for_generator(node)
        }"""
new = """        if has_grammar_error = false
            this.check_grammar_for_generator(node)"""''')

P['g10'] = ('''# checkGrammarArrowFunction's MTS/CTS TERM dropped, so the reserved-syntax report
# never fires. PREDICTION: the diagpin RED on fnexpr_arrow_grammar.mts and nothing
# else at all — the one fixture whose EXTENSION is its input, and the row a corpus
# of `.ts` files could not have.''',
'''old = """                if is_mts_or_cts_file"""
new = """                if false"""''')

P['g11'] = ('''# THE HAS-TRAILING-COMMA term of the same guard dropped, so `<T,>` is reported as
# reserved syntax too. PREDICTION: diagcheck RED — an INVENTED line, the direction
# a subsequence CAN see — on the `.mts` fixture.''',
'''old = """            if this.list_has_trailing_comma(type_parameters)
                set reserved: false"""
new = """            if false
                set reserved: false"""''')

P['g12'] = ('''# ecma_lines_differ ANSWERS FALSE ALWAYS, so the line-terminator-before-arrow
# report never fires. PREDICTION: the diagpin RED on fnexpr_arrow_grammar.mts,
# losing TS1200. The row that says the local walk replaced a line map rather than
# skipping the question.''',
'''old = """        if end_pos <= start_pos
            return false
        let text b.source_slice(start_pos, end_pos)"""
new = """        if end_pos <= start_pos
            return false
        if end_pos > start_pos
            return false
        let text b.source_slice(start_pos, end_pos)"""''')

P['g13'] = ('''# ecma_lines_differ's CRLF PAIRING dropped, so a CR and the LF after it count as
# two breaks. PREDICTION: UNGATED, with a proof — the answer is a BOOLEAN, so
# counting one break as two cannot change it. The row exists because the pairing is
# the reference's own `fallthrough` and looks load-bearing; it is not, at THIS call
# site, and the day a caller wants a line NUMBER it becomes so.''',
'''old = """                var q i + 1
                if q < n
                {
                    if ((text[q as size_t] as int) & 255) = 10
                        set q: q + 1
                }"""
new = """                var q i + 1"""''')

P['g14'] = ('''# hasContextSensitiveParameters' `this` TERM dropped, so a function expression whose
# body mentions `this` is no longer context sensitive. PREDICTION: the FNPIN RED on
# fnexpr_sensitive.ts with the SENSITIVE column moving, and the fngate's SENSITIVE
# count falling while its ROW count stands. The sharpest statement that the pin
# reads a decision and not a product.''',
'''old = """            if explicit_this = false
                return (AstNode.flags_of(node) & NodeFlagsContainsThis) <> 0"""
new = """            if explicit_this = false
                return false"""''')

P['g15'] = ('''# hasContextSensitiveParameters' TYPE-PARAMETER guard dropped, so a generic function
# expression is judged by its parameters. PREDICTION: the FNPIN RED — `generic` in
# fnexpr_sensitive.ts flips — and the fngate's SENSITIVE column moves. The
# reference's own comment is the whole content of the line: *functions with type
# parameters are not context sensitive*.''',
'''old = """        ; "Functions with type parameters are not context sensitive."
        if AstNode.type_parameters_of(node) <> null
            return false
        let params AstNode.parameters_of(node)"""
new = """        let params AstNode.parameters_of(node)"""''')

P['g16'] = ('''# THE RETURN WALK'S ARM LIST opened — every kind descends, so the walk crosses a
# nested function's boundary. PREDICTION: the FNPIN RED on fnexpr_sensitive.ts, and
# the fngate's SENSITIVE count RISING rather than falling. A control that moves a
# gate in the direction that looks like progress.''',
'''old = """        if Checker.kind_can_contain_return_statement(k) = false
            return false"""
new = """        if k = KindUnknown
            return false"""''')

P['g17'] = ('''# THE YIELD WALK'S FUNCTION-LIKE SKIP dropped, so the walk descends into a nested
# function and finds its yields. PREDICTION: the FNPIN RED on fnexpr_sensitive.ts's
# second generator, which is the fixture written for exactly this arm. The
# reference's comment says why the skip is there: *we will not include
# methods/accessors of a class because they would require first descending into the
# class; this is by design.*''',
'''old = """        if AstNode.is_function_like(node)
        {
            let name AstNode.name_of(node)"""
new = """        if AstNode.kind_of(node) = KindUnknown
        {
            let name AstNode.name_of(node)"""''')

P['g18'] = ('''# isContextSensitive's BINARY arm accepts every operator, not just `||` and `??`.
# PREDICTION: the FNPIN RED on fnexpr_sensitive.ts — `plus` flips — and the
# fngate's SENSITIVE column moves. Only those two propagate a contextual type to
# both operands, which is the whole content of that line.''',
'''old = """            if op = KindBarBarToken
                set propagates: true
            if op = KindQuestionQuestionToken
                set propagates: true"""
new = """            if op <> KindUnknown
                set propagates: true"""''')

P['g19'] = ('''# getContextualSignature's UNION arm takes the FIRST callable member instead of
# stopping at compareSignaturesIdentical. PREDICTION: UNGATED, WITH A PROOF FOUND
# BY THE ROW AND NOT BEFORE IT. The arm needs a contextual type whose flags carry
# Union — and a union TYPE NODE stops at `get-type-from-type-node 197` one chapter
# out, so no union type ever reaches getApparentTypeOfContextualType here at all.
# The whole union half of this function, the identity comparison behind it and
# createUnionSignature are written from the reference and input-free. ★The first
# fixture for this row used a type ALIAS and stopped even earlier, which hid the
# real containment behind a shallower one.''',
'''old = """                    if count <> 0
                    {
                        this.record_unported("compare-signatures-identical", AstNode.kind_of(node))
                        return null
                    }"""
new = """                    if count < 0
                    {
                        this.record_unported("compare-signatures-identical", AstNode.kind_of(node))
                        return null
                    }"""''')

P['g20'] = ('''# isAritySmaller's `this` DECREMENT dropped, so a contextual signature is refused
# for a function whose first parameter is an explicit `this`. PREDICTION: the FNPIN
# RED on fnexpr_contextual.ts's `withthis` group, ctxsig 1 -> 0, and nothing else.''',
'''old = """            if count <> 0
            {
                if AstNode.is_this_parameter(ps[0])
                    set target_parameter_count: target_parameter_count - 1
            }"""
new = """            if count < 0
            {
                if AstNode.is_this_parameter(ps[0])
                    set target_parameter_count: target_parameter_count - 1
            }"""''')

P['g21'] = ('''# isAritySmaller stops counting NOTHING — the three break conditions dropped, so an
# optional, defaulted or rest parameter counts towards the required arity.
# PREDICTION: the FNPIN RED on fnexpr_contextual.ts's optional/defaulted/rest
# groups, all three losing their contextual signature.''',
'''old = """                if AstNode.initializer_of(param) <> null
                    break
                if AstNode.question_token_of(param) <> null
                    break
                if AstNode.dot_dot_dot_token_of(param) <> null
                    break"""
new = """                if AstNode.kind_of(param) = KindUnknown
                    break"""''')

P['g22'] = ('''# getContextualCallSignature accepts a set of ANY size instead of exactly one.
# PREDICTION: the stoppin RED on fnexpr_stops.ts — the getIntersectedSignatures
# stop disappears — and the FNPIN's ctxsig column moves wherever an overload set is
# the contextual type. The reference's own header is the rule: *a contextual type
# provides a contextual signature if it has a SINGLE call signature*.''',
'''old = """        if applicable = 1
            return only"""
new = """        if applicable >= 1
            return only"""''')

P['g23'] = ('''# assignNonContextualParameterTypes not called. PREDICTION: diagcheck UNGATED with
# a NUMBER and the diagpin RED — this is where TS7006 comes from, and the
# reference's own comment says the call exists to force that resolution. A row
# that looks like a no-op removed and is a diagnostic removed.''',
'''old = """                set fn_pin_arm: 1
                this.assign_non_contextual_parameter_types(sig)"""
new = """                set fn_pin_arm: 1
                if fn_pin_arm < 0
                    this.assign_non_contextual_parameter_types(sig)"""''')

P['g24'] = ('''# assignContextualParameterTypes not called — the arm that replaced this slice's
# first-draft stop. PREDICTION: the FNPIN unmoved (the arm is still recorded) and
# the stoppin/diagpin moved, because the parameters of every contextually typed
# function stop being resolved. The row that says an ARM COLUMN is not a
# measurement of what the arm DID.''',
'''old = """                this.assign_contextual_parameter_types(sig, contextual_signature as ref[Signature])"""
new = """                if fn_pin_arm < 0
                    this.assign_contextual_parameter_types(sig, contextual_signature as ref[Signature])"""''')

P['g25'] = ('''# assignParameterType's ADD-OPTIONALITY term forced to false, so an optional
# parameter's type never gains `undefined`. PREDICTION: UNGATED, AND THE REASON IS
# A HOLE IN THE INSTRUMENTS RATHER THAN IN THE CORPUS — which is the one §3.5v
# verdict that names a successor. **A parameter's RESOLVED TYPE has no artifact in
# this port**: the FNPIN prints the function's type identity, slice 86's `G` line
# prints a signature's type-parameter, parameter and minimum-argument COUNTS, and
# the T section can only speak for a unit whose check completes — which a
# contextually typed function does not, because it stops at getReturnTypeFromBody.
# The instrument that would gate this is a per-PARAMETER line on the member pin,
# and it belongs to the slice that opens getReturnTypeFromBody. ★g28 is the same
# hole read from the other end.''',
'''old = """        let widened this.add_optionality_ex(t as ref[Type], false, optional)"""
new = """        let widened this.add_optionality_ex(t as ref[Type], false, false)"""''')

P['g26'] = ('''# THE CONTEXT-CHECKED bit never set, so contextuallyCheck runs again on a second
# visit. PREDICTION: UNGATED, with the wall named. The bit can only be observed by
# a SECOND visit to one node, and the reference's own comment says where the
# second visit comes from: *obtaining the contextual type may recursively get back
# to here during overload resolution of the call*. Overload resolution is the call
# dimension, which this port has not opened, so nothing here visits a function
# expression twice. ★The memo is written anyway rather than left out — a report
# emitted twice is exactly what diagcheck's subsequence relation fails on, and the
# slice that opens the call dimension must find the guard already in place.''',
'''old = """        set links.context_checked: true"""
new = """        set links.context_checked: false"""''')

P['g27'] = ('''# tryGetTypeAtPosition's REST guard dropped, so an out-of-range position answers
# the last parameter's type instead of nothing. PREDICTION: the FNPIN RED on
# fnexpr_contextual.ts and the MEMPIN with it — a parameter typed off a position
# the contextual signature does not have is a well-formed WRONG type.''',
'''old = """        if pos < param_count
        {
            let p (signature.parameters as ref[Array[ref[Symbol]?]])[pos]"""
new = """        if pos <= param_count
        {
            let p (signature.parameters as ref[Array[ref[Symbol]?]])[pos]"""''')

P['g28'] = ('''# getTypeOfParameter's optionality disjunct halved — the INITIALIZER term dropped,
# which is the term this slice got wrong on its first draft and then inverted.
# PREDICTION: UNGATED, for g25's reason and no other — a parameter's resolved type
# has no artifact here. The row is kept anyway, and it is kept for §3.5cz's f14
# reason: it is the only written record that these two readers ask DIFFERENT
# questions of the same helper. Here an initializer MAKES a parameter optional
# (`f(x = 1)` accepts a call with no argument); in assignParameterType it is the
# reason NOT to add undefined, because the declared type is the initializer's. The
# first draft of this slice copied one condition into the other's place.''',
'''old = """            if AstNode.initializer_of(d) <> null
                set optional: true
            if Checker.is_optional_declaration(d)
                set optional: true"""
new = """            if Checker.is_optional_declaration(d)
                set optional: true"""''')

P['g29'] = ('''# getContextualTypeForObjectLiteralMethod reverted to the stop it was until this
# slice. PREDICTION: the FNPIN RED on fnexpr_contextual.ts's `holdermethod` group
# and the stoppin with it — the third kind loses the only door through which a
# contextual type reaches it.''',
'''old = """            if (AstNode.flags_of(node) & NodeFlagsInWithStatement) <> 0
                return null
            set contextual_type: this.get_contextual_type_for_object_literal_element(node, context_flags)"""
new = """            this.record_unported("get-contextual-type-for-object-literal-method", AstNode.kind_of(node))
            return null"""''')

P['g30'] = ('''# THE DEFERRED HALF'S BODY WALK dropped — checkSourceElement(body) not called.
# PREDICTION: the diagpin RED on fnexpr_deferred.ts, which loses every report in
# every body, with the FNPIN and the fngate unmoved. The narrowest statement of
# this slice's product: everything else about the chapter is a decision, and this
# one line is the walk.''',
'''old = """        if AstNode.kind_of(body) = KindBlock
        {
            this.check_source_element(body)
            return
        }"""
new = """        if AstNode.kind_of(body) = KindBlock
            return"""''')

P['g31'] = ('''# getContextuallyTypedParameterType's IIFE STOP removed, so an immediately invoked
# function expression's parameters fall through to the contextual-signature branch.
# PREDICTION: the stoppin RED on fnexpr_stops.ts and the FNPIN with it. An IIFE has
# no contextual type at all, so the answer becomes nil where it was a stop — a
# quiet wrong answer replacing a loud one.''',
'''old = """        if Checker.immediately_invoked_function_expression(fn) <> null
        {
            this.record_unported("get-effective-call-arguments", KindParameter)
            return null
        }"""
new = """        if Checker.immediately_invoked_function_expression(fn) = null
        {
            if AstNode.kind_of(fn) = KindUnknown
                this.record_unported("get-effective-call-arguments", KindParameter)
            return null
        }"""''')

P['g32'] = ('''# checkSignatureDeclaration not called at the tail of contextuallyCheck.
# PREDICTION: diagcheck UNGATED with a NUMBER and the diagpin RED — the signature
# walk is where a function expression's parameter and return annotations are
# checked, and it has been in this file since slice 52 with only DECLARATIONS
# reaching it.''',
'''old = """        this.check_signature_declaration(node)
    }

    ; getContextualSignature."""
new = """        if fn_pin_arm < 0
            this.check_signature_declaration(node)
    }

    ; getContextualSignature."""''')

for k, (doc, body) in P.items():
    with open(os.path.join(D, k + '.py'), 'w') as f:
        f.write(doc + '\n')
        f.write('import sys\n')
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

control "g01 THE PREMISE (checkExpressionWorker's two arms) reverted to their stop" $CHECKER "$PATCHDIR/g01.py"
control "g02 the OBJECT-LITERAL METHOD arm reverted to its stop" $CHECKER "$PATCHDIR/g02.py"
control "g03 the DEFERRAL not made — checkNodeDeferred not called" $CHECKER "$PATCHDIR/g03.py"
control "g04 the EARLY RETURN put back in front of the drain" $CHECKER "$PATCHDIR/g04.py"
control "g05 the DRAIN's function-like arm removed" $CHECKER "$PATCHDIR/g05.py"
control "g06 the DRAIN's ACCESSOR arm removed (the defect this slice repaired)" $CHECKER "$PATCHDIR/g06.py"
control "g07 checkCollisionsForDeclarationName not called" $CHECKER "$PATCHDIR/g07.py"
control "g08 the GRAMMAR CHECK not called" $CHECKER "$PATCHDIR/g08.py"
control "g09 the generator check's KIND GUARD dropped" $CHECKER "$PATCHDIR/g09.py"
control "g10 checkGrammarArrowFunction's MTS/CTS term dropped" $CHECKER "$PATCHDIR/g10.py"
control "g11 the HAS-TRAILING-COMMA term of the same guard dropped" $CHECKER "$PATCHDIR/g11.py"
control "g12 ecma_lines_differ answers FALSE always" $CHECKER "$PATCHDIR/g12.py"
control "g13 ecma_lines_differ's CRLF PAIRING dropped" $CHECKER "$PATCHDIR/g13.py"
control "g14 hasContextSensitiveParameters' this TERM dropped" $CHECKER "$PATCHDIR/g14.py"
control "g15 hasContextSensitiveParameters' TYPE-PARAMETER guard dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 the RETURN WALK's arm list opened" $CHECKER "$PATCHDIR/g16.py"
control "g17 the YIELD WALK's function-like skip dropped" $CHECKER "$PATCHDIR/g17.py"
control "g18 isContextSensitive's BINARY arm accepts every operator" $CHECKER "$PATCHDIR/g18.py"
control "g19 getContextualSignature's UNION arm takes the first callable member" $CHECKER "$PATCHDIR/g19.py"
control "g20 isAritySmaller's this DECREMENT dropped" $CHECKER "$PATCHDIR/g20.py"
control "g21 isAritySmaller stops counting NOTHING" $CHECKER "$PATCHDIR/g21.py"
control "g22 getContextualCallSignature accepts a set of ANY size" $CHECKER "$PATCHDIR/g22.py"
control "g23 assignNonContextualParameterTypes not called" $CHECKER "$PATCHDIR/g23.py"
control "g24 assignContextualParameterTypes not called" $CHECKER "$PATCHDIR/g24.py"
control "g25 assignParameterType's ADD-OPTIONALITY term forced false" $CHECKER "$PATCHDIR/g25.py"
control "g26 the CONTEXT-CHECKED bit never set" $CHECKER "$PATCHDIR/g26.py"
control "g27 tryGetTypeAtPosition's REST guard dropped" $CHECKER "$PATCHDIR/g27.py"
control "g28 getTypeOfParameter's optionality disjunct halved" $CHECKER "$PATCHDIR/g28.py"
control "g29 getContextualTypeForObjectLiteralMethod reverted to its stop" $CHECKER "$PATCHDIR/g29.py"
control "g30 the DEFERRED HALF's body walk dropped" $CHECKER "$PATCHDIR/g30.py"
control "g31 getContextuallyTypedParameterType's IIFE STOP removed" $CHECKER "$PATCHDIR/g31.py"
control "g32 checkSignatureDeclaration not called at the tail" $CHECKER "$PATCHDIR/g32.py"

echo
echo "################################################################"
bold "DONE - read every row against its PREDICTION, not against its colour."
