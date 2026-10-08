#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice89.sh — the slice-89 battery: THE CALL AND THE NEW EXPRESSION, and
# a chapter most of whose body sits behind ONE line.
#
# ★★★ THE SLICE CLOSES THE WORK LIST'S FIRST REACHABLE ROW AND MOVES IT WHOLE.
# `check-call-expression` was 150 events over 85 units at 214 (the CallExpression)
# and 17 over 14 at 215 (the NewExpression) — both are ZERO, and the corpus's stop
# EVENT TOTAL does not move by one: every unit that stopped at the call now stops
# at what its CALLEE actually is (check-identifier +87, check-property-access-
# expression +66, check-super-expression +12, and two singles). That is slice 88's
# finding three in its purest form — the row bought TRUTH, not a diagnostic.
#
# ★★★ SO THE BATTERY HAS TWO HALVES AND THE SECOND ONE IS THE REPORT. Everything
# in checkCallExpression BELOW its second line — the TS7009 arm, the super→void
# answer, the deprecation row, the fresh-symbol arm and the assertion pair — is
# behind `getResolvedSignature`, which cannot answer while resolveCall is unported.
# Six rows force those lines and NOTHING MOVES; that is not a hole in the battery,
# it is the measurement of where the wall is.
#
# ★★★ AND THE ONE PLACE THE SLICE DOES SPEAK IS AN ORDER. checkGrammarTypeArguments
# is checkCallExpression's FIRST line, ahead of the resolution — so `g<>()` reports
# TS1099 although nothing about the call can be resolved. g18 moves that call one
# line down, behind the signature, and the two reports vanish: the reference's own
# statement ORDER is what makes this chapter productive at all.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts are stage 1's.
#
# Usage (nothing may edit the tree while this runs, and no second harness may own
# tests/out — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1
#   packages/tscaly/tests/controls-slice89.sh 2>&1 | tee /tmp/battery89.log
#
set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.1/tscaly/checker.scaly
AST=$PKG/0.1.1/tscaly/ast.scaly
PARSER=$PKG/0.1.1/tscaly/parser.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# ★ ONE MECHANISM PER FILE (slice 72's rule). The last two break it on purpose:
# `checker_binary_comma_in_call.ts` is slice 88's own negative control, which THIS
# slice expired — it now emits the TS2695 that entry said the port could not reach
# — and `parser_binary_ops.ts` is the forty-one-operator file, kept because half of
# this battery's rows move a stop rather than a diagnostic and the STOPPIN is what
# reads that.
PINFILES="
$FIX/checker_call_callee_literal.ts
$FIX/checker_call_optional_chain.ts
$FIX/checker_call_empty_type_args.ts
$FIX/checker_call_super.ts
$FIX/checker_binary_comma_in_call.ts
$FIX/checker_binary_comma_unused.ts
$FIX/parser_binary_ops.ts
"
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl89)

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
      "$("$WORK/tscaly_types" --diags "$f" 2>/dev/null | tr '\n' '|')"
  done
}

tags_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

stops_of() {
  local f
  for f in $PINFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" --stops "$f" 2>/dev/null | tr '\n' '|')"
  done
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

DIAG_BASE=""; DIAG_LINES=""; DIAG_DIAGS=""; STOP_BASE=""

baseline() {
  echo "################################################################"
  bold "BASELINE — five instruments"
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
  STOP_BASE=$(stopgate)
  echo
  echo "  the STOPPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.stops"
  echo
  echo "  the TAGPIN on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  echo
  echo "  BASELINE   diagcheck $DIAG_BASE consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
  echo "             stopgate  (matched units speaking events other) = $STOP_BASE"
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
  stop=$(stopgate)
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
    diff "$WORK/base.diags" "$WORK/ctl.diags" | sed 's/^/    /'
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
    diff "$WORK/base.stops" "$WORK/ctl.stops" | sed 's/^/    /'
    moved=1
  fi
  if [ "$stop" = "$STOP_BASE" ]; then
    echo "  stopgate  unmoved — $stop"
  else
    green "stopgate  MOVED   $STOP_BASE -> $stop   (matched units speaking events other)"
    moved=1
  fi
  if [ "$moved" = 0 ]; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all five, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL FIVE AND NOTHING MOVED AT ALL."
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

P['g01'] = ('''# THE PREMISE — both dispatch arms reverted to the stop. PREDICTION: TAGPIN +
# STOPPIN RED on every fixture that holds a call, DIAGPIN RED on the two TS1099 and
# on slice 88's comma-in-call, and the STOPGATE moves by the whole row.''',
'''old = """            return this.check_call_expression(node, check_mode)
        }
        if k = KindNewExpression
            return this.check_call_expression(node, check_mode)"""
new = """            this.record_unported("check-call-expression", k)
            return null
        }
        if k = KindNewExpression
        {
            this.record_unported("check-call-expression", k)
            return null
        }"""''')

P['g02'] = ('''# checkGrammarTypeArguments never called. PREDICTION: DIAGPIN RED — the two TS1099
# of checker_call_empty_type_args go, and diagcheck stays ungated because a
# subsequence breaks on what you INVENT and not on what you LOSE (slice 73).''',
'''old = """        this.check_grammar_type_arguments(AstNode.type_arguments_of(node))
        let mark this.unported_mark()
        let sig this.get_resolved_signature(node, check_mode)"""
new = """        let mark this.unported_mark()
        let sig this.get_resolved_signature(node, check_mode)"""''')

P['g18'] = ('''# checkGrammarTypeArguments moved BELOW the resolution — the reference's own
# statement ORDER broken, and nothing else. PREDICTION: DIAGPIN RED with exactly
# g02's diff, which is the claim: the grammar check produces this chapter's only
# corpus-visible diagnostics *because* it stands in front of a wall.
#
# ★ THE FIRST DRAFT OF THIS ROW MOVED THE CALL ONE LINE TOO FEW — below the
# resolution but ABOVE the early-out that reads its mark — so it still ran, and the
# row came back UNGATED while claiming to have tested the order. A control that
# does not actually reach the state it names reports a real green for a false
# reason, which is ctl.sh's anchor rule one level up: the anchor was right and the
# PATCH was not.''',
'''old = """        this.check_grammar_type_arguments(AstNode.type_arguments_of(node))
        let mark this.unported_mark()
        let sig this.get_resolved_signature(node, check_mode)
        if this.unported_mark() <> mark
            return null"""
new = """        let mark this.unported_mark()
        let sig this.get_resolved_signature(node, check_mode)
        if this.unported_mark() <> mark
            return null
        this.check_grammar_type_arguments(AstNode.type_arguments_of(node))"""''')

P['g03'] = ('''# resolveCallExpression's CALLEE check removed — it reports in its place, so the
# rest of the pass is not walked into a hole (ctl.sh's slice-32 rule). PREDICTION:
# STOPPIN RED and the STOPGATE moved: the 153 events this slice redistributed come
# back to one tag.''',
'''old = """        let mark this.unported_mark()
        let ft this.check_expression(expr)
        if this.unported_mark() <> mark
            return null
        if ft = null
            return null
        if Checker.is_call_chain(node)"""
new = """        let mark this.unported_mark()
        this.record_unported("ctl-callee-check-removed", AstNode.kind_of(expr))
        return null
        let ft this.check_expression(expr)
        if this.unported_mark() <> mark
            return null
        if ft = null
            return null
        if Checker.is_call_chain(node)"""''')

P['g04'] = ('''# resolveNewExpression's callee check removed, same shape. PREDICTION: STOPPIN RED
# on checker_call_callee_literal alone — it is the only pin file with a `new`.''',
'''old = """        let expr callee as ref[AstNode]
        let mark this.unported_mark()
        let et this.check_expression(expr)
        if this.unported_mark() <> mark
            return null
        if et = null
            return null
        this.record_unported("check-non-null-type", AstNode.kind_of(expr))"""
new = """        let expr callee as ref[AstNode]
        let mark this.unported_mark()
        this.record_unported("ctl-new-callee-check-removed", AstNode.kind_of(expr))
        return null
        let et this.check_expression(expr)
        if this.unported_mark() <> mark
            return null
        if et = null
            return null
        this.record_unported("check-non-null-type", AstNode.kind_of(expr))"""''')

P['g05'] = ('''# The SUPER branch never taken. PREDICTION: UNGATED, and it is a proof rather than
# a hole — checkExpression of a bare `super` lands on the DISPATCH's
# `check-super-expression` with the same detail, so the two spellings coincide
# (§3.5v's fourth verdict).''',
'''old = """        if AstNode.kind_of(expr) = KindSuperKeyword
        {"""
new = """        if false
        {"""''')

P['g06'] = ('''# The import-call fork forced TRUE. PREDICTION: STOPPIN + TAGPIN RED on every pin
# file with a call — every one of them becomes `resolve-untyped-call`.''',
'''old = """        if Parser.is_import_call(node)
        {
            this.record_unported("resolve-untyped-call", KindCallExpression)"""
new = """        if true
        {
            this.record_unported("resolve-untyped-call", KindCallExpression)"""''')

P['g07'] = ('''# The import-call fork never taken. PREDICTION: UNGATED — the DISPATCH has already
# sent every import call to `check-import-call-expression`, so this branch has no
# input on this path. The row is what makes that an argument instead of a claim.''',
'''old = """        if Parser.is_import_call(node)
        {
            this.record_unported("resolve-untyped-call", KindCallExpression)"""
new = """        if false
        {
            this.record_unported("resolve-untyped-call", KindCallExpression)"""''')

P['g08'] = ('''# is_call_chain answers FALSE. PREDICTION: STOPPIN RED on
# checker_call_optional_chain — `(1)?.()` stops at check-non-null-type instead of
# get-optional-expression-type, which is the two exits of one `if`.''',
'''old = """    function is_call_chain(n: ref[AstNode]) returns bool
    {
        if AstNode.kind_of(n) <> KindCallExpression
            return false"""
new = """    function is_call_chain(n: ref[AstNode]) returns bool
    {
        if true
            return false"""''')

P['g09'] = ('''# is_call_chain answers TRUE. PREDICTION: STOPPIN RED on
# checker_call_callee_literal — g08's complement, and the pair is what says the
# NodeFlagsOptionalChain test decides rather than the kind.''',
'''old = """    function is_call_chain(n: ref[AstNode]) returns bool
    {
        if AstNode.kind_of(n) <> KindCallExpression
            return false"""
new = """    function is_call_chain(n: ref[AstNode]) returns bool
    {
        if true
            return true"""''')

P['g10'] = ('''# resolveSignature's NewExpression arm dropped to the switch's DEFAULT — the
# reference's own panic, held here as a row. PREDICTION: STOPPIN RED on
# checker_call_callee_literal, whose `new (1)()` is the only `new` in the pins.''',
'''old = """        if k = KindNewExpression
            return this.resolve_new_expression(node, check_mode)"""
new = """        if k = KindNewExpression
        {
            this.record_unported("resolve-signature-unhandled", k)
            return null
        }"""''')

P['g11'] = ('''# The MEMO removed — getResolvedSignature recomputes on every ask. PREDICTION:
# UNGATED, and the reason is worth the row: the shape that would double-check a
# call node is intercepted one level up, by getQuickTypeOfExpression's own call arm,
# so no unit of this corpus asks twice. Slice 88's memo had a red row; this one has
# an argument.''',
'''old = """        let links this.signature_link_of(node)
        let cached links.resolved_signature
        if cached <> null
        {
            if (cached as ref[Signature]) <> resolving_signature
                return cached
        }
        if links.signature_stopped"""
new = """        let links this.signature_link_of(node)
        let cached: ref[Signature]? null
        if false
        {
            if (cached as ref[Signature]) <> resolving_signature
                return cached
        }
        if false"""''')

P['g12'] = ('''# The memo's INCOMPLETENESS bit removed — a stop is cached as a plain nil.
# PREDICTION: UNGATED for g11's reason, and it is the row that says so: slice 88
# paid for exactly this bit in type_node_links with a red diagcheck, and here the
# same defect cannot be reached.''',
'''old = """        if links.signature_stopped
        {
            this.replay_stop_mark()
            return null
        }"""
new = """        if false
        {
            this.replay_stop_mark()
            return null
        }"""''')

P['g13'] = ('''# checkDeprecatedSignature's declaration guard removed — it reports on every
# signature. PREDICTION: UNGATED — no signature reaches it, because resolveSignature
# always stops. One of the six rows that measure where the wall is.''',
'''old = """        if sig.declaration = null
            return
        this.record_unported("is-deprecated-declaration", AstNode.kind_of(node))"""
new = """        this.record_unported("is-deprecated-declaration", AstNode.kind_of(node))"""''')

P['g14'] = ('''# The fresh-unique-symbol arm forced taken. PREDICTION: UNGATED — the line is below
# getResolvedSignature.''',
'''old = """        if (return_type.flags & TypeFlagsESSymbolLike) <> 0
        {"""
new = """        if true
        {"""''')

P['g15'] = ('''# The assertion pair's VOID test dropped, so every expression-statement call takes
# the row. PREDICTION: UNGATED — below getResolvedSignature again.''',
'''old = """                    if (return_type.flags & TypeFlagsVoid) <> 0
                        set assertion_shape: true"""
new = """                    set assertion_shape: true"""''')

P['g16'] = ('''# The NewExpression TS7009 arm forced to report. PREDICTION: UNGATED — the arm is
# reached only with a signature that HAS a declaration, and this port has neither.''',
'''old = """                if constructs = false
                {"""
new = """                if true
                {"""''')

P['g17'] = ('''# The isCommonJSRequire row removed. PREDICTION: UNGATED — below
# getResolvedSignature, and the corpus's JavaScript `require` calls stop at their
# callee long before it.''',
'''old = """            if Parser.is_require_call(node, true)
            {
                this.record_unported("is-common-js-require", AstNode.kind_of(node))
                return null
            }"""
new = """            if false
            {
                this.record_unported("is-common-js-require", AstNode.kind_of(node))
                return null
            }"""''')

P['g19'] = ('''# A NIL WITHOUT A STOP — resolveCallExpression's checkNonNullType row removed so
# the function answers nil with nothing recorded. PREDICTION: diagcheck RED by
# INVENTION. It is slice 88's finding two re-run in a new place: a nil is how this
# port says *no claim*, and every caller above reads a nil with no stop as an
# ANSWER — getWidenedTypeForVariableLikeDeclaration turns it into a TS7005.''',
'''old = """        this.record_unported("check-non-null-type", AstNode.kind_of(expr))
        null
    }

    ; resolveNewExpression, to the same depth."""
new = """        null
    }

    ; resolveNewExpression, to the same depth."""''')

for k, (pred, body) in sorted(P.items()):
    src = "import sys\np = sys.argv[1]; s = open(p).read()\n" + pred + "\n" + body + """
if old not in s:
    sys.exit(1)
if old == "":
    sys.exit(1)
s = s.replace(old, new, 1)
open(p, 'w').write(s)
"""
    open(os.path.join(D, k + '.py'), 'w').write(src)
print("wrote", len(P))
MKPATCHES

baseline

control "g01 both dispatch arms reverted to the stop (the premise)" $CHECKER "$PATCHDIR/g01.py"
control "g02 checkGrammarTypeArguments never called" $CHECKER "$PATCHDIR/g02.py"
control "g18 checkGrammarTypeArguments moved BELOW the resolution" $CHECKER "$PATCHDIR/g18.py"
control "g03 resolveCallExpression's callee check removed" $CHECKER "$PATCHDIR/g03.py"
control "g04 resolveNewExpression's callee check removed" $CHECKER "$PATCHDIR/g04.py"
control "g05 the super branch never taken" $CHECKER "$PATCHDIR/g05.py"
control "g06 the import-call fork forced TRUE" $CHECKER "$PATCHDIR/g06.py"
control "g07 the import-call fork never taken" $CHECKER "$PATCHDIR/g07.py"
control "g08 is_call_chain answers FALSE" $CHECKER "$PATCHDIR/g08.py"
control "g09 is_call_chain answers TRUE" $CHECKER "$PATCHDIR/g09.py"
control "g10 resolveSignature's NewExpression arm dropped to the default" $CHECKER "$PATCHDIR/g10.py"
control "g11 the MEMO removed" $CHECKER "$PATCHDIR/g11.py"
control "g12 the memo's incompleteness BIT removed" $CHECKER "$PATCHDIR/g12.py"
control "g13 checkDeprecatedSignature's declaration guard removed" $CHECKER "$PATCHDIR/g13.py"
control "g14 the fresh-unique-symbol arm forced taken" $CHECKER "$PATCHDIR/g14.py"
control "g15 the assertion pair's void test dropped" $CHECKER "$PATCHDIR/g15.py"
control "g16 the NewExpression TS7009 arm forced to report" $CHECKER "$PATCHDIR/g16.py"
control "g17 the isCommonJSRequire row removed" $CHECKER "$PATCHDIR/g17.py"
control "g19 a NIL WITHOUT A STOP — the checkNonNullType row removed" $CHECKER "$PATCHDIR/g19.py"

echo
echo "################################################################"
bold "DONE — read every row against its PREDICTION, not against its colour."
