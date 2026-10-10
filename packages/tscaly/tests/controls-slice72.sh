#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice72.sh — the slice-72 battery: THE DECLARATION'S INITIALIZER.
# checkDeclarationInitializer, getQuickTypeOfExpression's five arms,
# widenTypeInferredFromInitializer, getWidenedLiteralTypeForInitializer,
# getWidenedLiteralType and isFreshLiteralType — plus the ast.IsImportCall this
# slice had to write to route the CallExpression arm of the expression dispatch.
#
# ★★★ TWO INSTRUMENTS, AND THE PIN IS THE POSITIVE ONE. What this slice produces
# is a WORK LIST — 208 units moved off `check-declaration-initializer` onto the
# rows behind it — and a work list is exactly what the pin over fixture TAGS
# reads. diagcheck is the negative instrument here for the second slice running:
# the chapter adds no diagnostic of its own, so a diagcheck move means a report
# was invented or lost somewhere behind it, which is worth catching and is not
# the product.
#
# ★★ THE PIN'S OWN PRECONDITION IS THAT EACH FIXTURE HAS EXACTLY ONE REACHABLE
# FIRST STOP, and getting that right cost three iterations rather than one — the
# tag is FIRST-WINS, so a `declare const p: Promise<number>` in front of the line
# under test records `get-type-from-type-node` and the fixture then measures the
# annotation instead of the arm. Every one of the six carries the shape it needs
# in its own header, and `checker_initializer_quick_call.ts` declares NOTHING on
# purpose.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts below are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice72.sh 2>&1 | tee /tmp/battery72.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.2/tscaly/checker.scaly
PARSER=$PKG/0.1.2/tscaly/parser.scaly
FIX=$PKG/tests/fixtures

. packages/tscaly/tests/toolchain.sh || exit 2

# The fixtures the PIN reads — this slice's ELEVEN, the two `import(...)` files
# whose tag it moved, the `import.defer(...)` file that is the IsImportCall
# finding, and TWO controls that hold a literal but no initializer and must never
# move.
#
# ★★★ ELEVEN RATHER THAN SIX, AND THE SPLIT WAS THE BATTERY'S FIRST FINDING. The
# first draft wrote one file per ARM and put both sides of an arm in it — `await 1`
# beside `await p`, `Symbol(...)` beside `Symbol.for(...)`, `let b = true` beside
# `const cb = true`. Five rows then came back UNGATED that had predicted red, and
# every one of the five was the same mechanism rather than five findings: the
# unported tag is FIRST-WINS, so a second line in a file can never be seen to move.
# ★A fixture holding two gates holds one.
TAGFILES="
$FIX/checker_initializer_literal_widening.ts
$FIX/checker_initializer_boolean_widening.ts
$FIX/checker_initializer_boolean_const.ts
$FIX/checker_initializer_quick_assertion.ts
$FIX/checker_initializer_quick_assertion_const.ts
$FIX/checker_initializer_quick_await.ts
$FIX/checker_initializer_quick_await_opaque.ts
$FIX/checker_initializer_quick_call.ts
$FIX/checker_initializer_quick_new.ts
$FIX/checker_initializer_quick_symbol_call.ts
$FIX/checker_initializer_quick_symbol_for.ts
$FIX/parser_import_call.ts
$FIX/parser_import_call_type_args.ts
$FIX/parser_import_defer_call.ts
$FIX/checker_expression_string_literal.ts
$FIX/checker_expression_null_statement.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "diagcheck compares against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl72)

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
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.2/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.2/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
}

tags_of() {
  local f
  for f in $TAGFILES; do
    printf '%s\t%s\n' "$(basename "$f")" \
      "$("$WORK/tscaly_types" "$f" 2>/dev/null | grep '^UNPORTED ' | head -1 | cut -d' ' -f3-)"
  done
}

DIAG_BASE=""
DIAG_LINES=""
DIAG_DIAGS=""

baseline() {
  echo "################################################################"
  bold "BASELINE — two instruments"
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
  sed -n '/^diagcheck/,$p' "$WORK/base.diag" | sed 's/^/  /'
  if [ "$rc" != 0 ]; then
    red "the diagnostics instrument is already red on the unpatched tree — fix that first."
    exit 2
  fi
  tags_of > "$WORK/base.tags"
  echo
  echo "  the PIN — the fixtures' unported tags on the unpatched tree:"
  sed 's/^/    /' "$WORK/base.tags"
  if grep -q '	$' "$WORK/base.tags"; then
    red "a fixture answers NO tag — the pin would be comparing two empties."
    exit 2
  fi
  echo
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics"
}

control() {   # $1 = label, $2 = space-separated files, $3 = python patch file
  echo
  echo "################################################################"
  bold "CONTROL: $1"
  local files="$2" f i=0
  for f in $files; do cp "$f" "$WORK/orig.$i"; i=$((i+1)); done
  PATCHED_FILES="$files"
  if ! python3 "$3" $files; then
    red "the patch did not apply — the anchor moved. The row measures nothing."
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""
    return 1
  fi
  echo "  patched $files"
  if ! build_bins; then
    red "the patched tree did not build — the row measures nothing:"
    tail -5 "$WORK/build.log" | sed 's/^/    /'
    i=0; for f in $files; do cp "$WORK/orig.$i" "$f"; i=$((i+1)); done
    PATCHED_FILES=""
    return 1
  fi
  BIN=$WORK/tscaly_types "$DIAGCHECK" > "$WORK/ctl.diag" 2>&1
  local rc=$?
  local consistent differing speaking diags
  consistent=$(sed -n 's/^  consistent  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  differing=$(sed -n 's/^  differing  *\([0-9]*\)$/\1/p' "$WORK/ctl.diag")
  speaking=$(sed -n 's/^  units we speak on  *\([0-9]*\).*$/\1/p' "$WORK/ctl.diag")
  diags=$(sed -n 's/^.*(\([0-9]*\) diagnostics.*$/\1/p' "$WORK/ctl.diag")
  tags_of > "$WORK/ctl.tags"
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
  if [ "$rc" != 0 ]; then
    green "diagcheck RED $differing   (consistent $consistent, was $DIAG_BASE; speaking on $speaking/$diags, was $DIAG_LINES/$DIAG_DIAGS)"
  else
    echo "  diagcheck ungated — speaking on $speaking units with $diags diagnostics, was $DIAG_LINES/$DIAG_DIAGS."
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  pin       unmoved — all sixteen fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON BOTH INSTRUMENTS AND NOTHING MOVED AT ALL."
      echo "  Decide which of §3.5v's four kinds this is. A row that predicted"
      echo "  this is a measurement; a row that did not is a hole in the battery."
    fi
  fi
  return 0
}

PATCHDIR=$WORK/patches
mkdir -p "$PATCHDIR"

# ── the patches ─────────────────────────────────────────────────────────────
#
# Written first, ALL of them, so the dry run below can apply every one against a
# copy of the tree before a single build is spent (slice 57).

cat > "$PATCHDIR/g01.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PREMISE ROW: the whole chapter turned back into slice 71's stop.
# PREDICTION: the pin goes red on all six initializer fixtures and on the two
# `import(...)` files, and NOT on the two literal controls — which is what proves
# the pin measures this chapter and not something the corpus does around it.
old = """            let init_type this.check_declaration_initializer(declaration, check_mode, null)"""
new = """            this.record_unported("check-declaration-initializer", dk)
            return null
            let init_type this.check_declaration_initializer(declaration, check_mode, null)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The QUICK PATH never consulted: every initializer goes to checkExpressionCached.
# PREDICTION: pin red on the four fixtures whose tag IS a quick arm (assertion,
# await, call, symbol_call) plus the two `import(...)` files, and unmoved on the
# two widening fixtures, whose literals answer the same type either way.
old = """        var t this.get_quick_type_of_expression(expr)"""
new = """        var t: ref[Type]? null
        if false
            set t: this.get_quick_type_of_expression(expr)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The CONTEXTUAL branch taken whether or not a contextual type was passed. The one
# ported caller passes null, so this turns the branch into an unconditional stop.
# PREDICTION: pin red on every fixture whose initializer has no quick answer.
old = """            if contextual_type <> null
            {"""
new = """            if true
            {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The PADDING BLOCK entered for every declaration and both of its type gates
# forced true. PREDICTION: this is the row that MEASURES the population the two
# provably-inert gates stand in front of — if nothing moves, no parameter-rooted
# binding pattern with an initializer reaches this point at all, which is the
# argument the header makes and this row is what turns it into a number.
old = """        if Binder.is_part_of_parameter_declaration(declaration)
        {
            let name AstNode.name_of(declaration)
            let nk Checker.kind_or_unknown(name)
            if nk = KindObjectBindingPattern
            {
                if Checker.is_object_literal_type(ty)
                {"""
new = """        if true
        {
            let name AstNode.name_of(declaration)
            let nk Checker.kind_or_unknown(name)
            if nk = KindObjectBindingPattern
            {
                if true
                {"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """            if nk = KindArrayBindingPattern
            {
                if Checker.is_tuple_type(ty)
                {"""
new = """            if nk = KindArrayBindingPattern
            {
                if true
                {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The AWAIT arm dropped. PREDICTION: pin red on quick_await, whose tag becomes the
# expression dispatch's `check-await-expression`.
old = """        if ek = KindAwaitExpression
        {"""
new = """        if false
        {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The AWAIT arm's RECURSION dropped and the report made unconditional — the arm
# then claims getAwaitedType for every await rather than only for one whose
# operand has a quick type. PREDICTION: the pin does not move (quick_await's FIRST
# line already stops there and the tag is first-wins), so the number this row
# owes is diagcheck's: it turns `await x` from a dispatch stop into an earlier one
# for every unit in the corpus that has one.
old = """            let inner_type this.get_quick_type_of_expression(inner as ref[AstNode])
            if this.unported_mark() <> mark
                return null
            if inner_type <> null
            {"""
new = """            let inner_type this.get_quick_type_of_expression(inner as ref[AstNode])
            if this.unported_mark() <> mark
                return null
            if true
            {"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The CALL arm dropped whole. PREDICTION: pin red on quick_call and on
# quick_symbol_call — both fall through to the dispatch's `check-call-expression`.
old = """        if ek = KindCallExpression
        {
            var eligible true"""
new = """        if false
        {
            var eligible true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The call arm's `super` conjunct dropped. PREDICTION: ungated — `super.m()` in an
# initializer needs a class with a base class and a property initializer, and the
# class dimension stops long before this point. The row exists to say so with a
# number rather than by argument.
old = """            if Checker.kind_or_unknown(AstNode.expression_of(expr)) = KindSuperKeyword
                set eligible: false"""
new = """            if false
                set eligible: false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The call arm's REQUIRE conjunct dropped, so `const x = require("m")` takes the
# quick path. PREDICTION: ungated on the pin — check_variable_like_standard's alias
# branch already owns that shape — and a diagcheck number if any corpus unit's
# CommonJS require reaches the type before the alias check.
old = """            if Parser.is_require_call(expr, true)
                set eligible: false"""
new = """            if false
                set eligible: false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The call arm's IMPORT conjunct dropped. PREDICTION: pin red on the two
# `import(...)` fixtures and on parser_import_defer_call — an import call would
# then be answered by the quick path instead of falling through to
# checkImportCallExpression, which is a different row of the work list.
old = """            if Parser.is_import_call(expr)
                set eligible: false"""
new = """            if false
                set eligible: false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The Symbol term never undecidable — i.e. the port CLAIMS isSymbolOrSymbolForCall
# is false for every call. PREDICTION: pin red on quick_symbol_call, whose tag
# becomes the call arm's own stop instead of the global lookup's.
old = """                if this.symbol_call_undecidable(expr)"""
new = """                if false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The `Symbol.for` PROPERTY-ACCESS REWRITE dropped: the callee is then the property
# access itself, which is not an Identifier, so the term answers false.
# PREDICTION: pin red on quick_symbol_call — its SECOND line moves, and because
# the file's first line is `Symbol("x")` the tag does not, so the row is a proof
# that a two-line fixture is not two gates. If the pin is unmoved, that is the
# finding and the fixture needs the two lines swapped.
old = """            if AstNode.text_is(nm as ref[AstNode], "for")
                    set left: AstNode.expression_of(left as ref[AstNode])"""
new = """            if false
                    set left: AstNode.expression_of(left as ref[AstNode])"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The NEW arm dropped. PREDICTION: pin red on quick_call, whose second line is
# `new Date()` — but only if the FIRST line's arm is what moves, which it is not,
# so this row is g12's shape again and its verdict is a statement about the
# fixture's order as much as about the arm.
old = """        if ek = KindNewExpression
        {
            this.record_unported("get-return-type-of-single-non-generic-signature", ek)
            return null
        }"""
new = """        if false
        {
            this.record_unported("get-return-type-of-single-non-generic-signature", ek)
            return null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The ASSERTION arm dropped. PREDICTION: pin unmoved on quick_assertion — its tag
# is `check-assertion` either way, because check_variable_like_declaration checks
# the initializer AGAIN after the symbol's type — and diagcheck RED, because with
# the arm the declaration's type resolves and the function runs on to
# checkCollisionsForDeclarationName, and without it it returns at `symbol_type =
# null`. THIS ROW IS THE ONE THAT SHOWS THE TWO INSTRUMENTS ANSWER DIFFERENT
# QUESTIONS.
old = """        if assertion
        {
            let type_node AstNode.type_of(expr)"""
new = """        if false
        {
            let type_node AstNode.type_of(expr)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The assertion arm's IsConstTypeReference EXCLUSION dropped, so `1 as const`
# answers getTypeFromTypeNode of a bare `const` type reference — which is a
# TypeReference arm this port does not have, i.e. a DIFFERENT stop.
# PREDICTION: pin red on quick_assertion, whose third line then reports
# `get-type-from-type-reference` before the file's own `check-assertion`.
old = """                if Parser.is_const_type_reference(type_node) = false"""
new = """                if false = false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The literal arm reads `expr` instead of `node` — the reference's own asymmetry
# "fixed". PREDICTION: UNGATED, and the silence is the finding: a parenthesised
# literal reaches the same type through checkExpressionCached, so the two spellings
# differ only in which function computes it. The row exists because the asymmetry
# is the kind of thing a later reader tidies away, and this is the measurement
# that says what tidying it costs (nothing observable today) and what it breaks
# (the call graph the port claims to reproduce).
old = """        let k AstNode.kind_of(node)
        var literal false"""
new = """        let k AstNode.kind_of(expr)
        var literal false"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """        if literal
            return this.check_expression(node)"""
new = """        if literal
            return this.check_expression(expr)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The literal arm's BOOLEAN-KEYWORD pair dropped — IsLiteralExpression alone.
# PREDICTION: pin red on boolean_widening, whose `let b = true` then has no quick
# answer and lands on checkExpressionCached instead. ★The TYPE is the same either
# way (the dispatch answers trueType too), so what moves is the tag only if the
# path through the widener differs — and it does not. If the pin is unmoved this
# row is a proof that the boolean half of the literal case is redundant HERE and
# load-bearing only for a caller that has no fallback.
old = """        if k = KindTrueKeyword
            set literal: true
        if k = KindFalseKeyword
            set literal: true"""
new = """        if false
            set literal: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The WIDENING SKIPPED: the initializer's own type returned unchanged.
# PREDICTION: pin red on boolean_widening — the fresh boolean literal type no
# longer needs booleanType, so its stop disappears and the file runs on. ★That is
# the widening's whole observable footprint in this port, which is why this row is
# the chapter's second premise.
old = """            let widened this.widen_type_inferred_from_initializer(declaration, init_type)"""
new = """            let widened init_type"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getWidenedLiteralTypeForInitializer's SHORT-CIRCUIT dropped: a `const` or
# `readonly` declaration widens its literal type too. PREDICTION: pin red on
# boolean_widening, whose THIRD line `const cb = true` then reaches the
# booleanType stop as well — but the file's first line already stops there, so the
# pin cannot see it and the number this row owes is diagcheck's, over every
# `const x = <boolean literal>` in the corpus.
old = """        if (Binder.combined_node_flags(declaration) & NodeFlagsConstant) <> 0
            return t
        if this.is_declaration_readonly(declaration)
            return t"""
new = """        if false
            return t"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# Only the READONLY half of the short-circuit dropped, so a `readonly r = "a"`
# widens where the reference keeps the literal type. PREDICTION: a diagcheck
# number if any corpus unit's readonly property initializer reaches here; the pin
# has no readonly fixture, deliberately — a class property's own stop
# (`check-object-type-for-duplicate-declarations`) comes first, which is why one
# was not written.
old = """        if this.is_declaration_readonly(declaration)
            return t"""
new = """        if false
            return t"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isFreshLiteralType ALWAYS TRUE. PREDICTION: ungated — every literal type this
# port makes for an initializer comes out of getFreshTypeOfLiteralType and is
# therefore already fresh, so the predicate has no false input yet. The row is the
# number behind that sentence, and its pair is g22.
old = """        let fresh Checker.is_fresh_literal_type(t)"""
new = """        let fresh true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isFreshLiteralType ALWAYS FALSE — nothing widens. PREDICTION: pin red on
# boolean_widening (its stop disappears), which together with g21's silence is the
# statement that every literal type reaching the widener is fresh: one direction
# is invisible and the other is not.
old = """        let fresh Checker.is_fresh_literal_type(t)"""
new = """        let fresh false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The widening arms' ORDER changed: EnumLike tested LAST rather than first.
# PREDICTION: ungated — nothing here sets TypeFlagsEnum or TypeFlagsEnumLiteral,
# so the arm has no input and its position cannot matter yet. The order is
# transcribed because an enum LITERAL type carries its base literal's flag too,
# and the day compute-enum-member-values lands this row goes red.
old = """            if (t.flags & TypeFlagsEnumLike) <> 0
            {
                ; getBaseTypeOfEnumLikeType → getDeclaredTypeOfSymbol of the
                ; member's parent.
                this.record_unported("get-base-type-of-enum-like-type", t.flags)
                return null
            }
            if (t.flags & TypeFlagsStringLiteral) <> 0
                return string_type"""
new = """            if (t.flags & TypeFlagsStringLiteral) <> 0
                return string_type"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """            if (t.flags & TypeFlagsBooleanLiteral) <> 0
            {
                ; c.booleanType — see the header.
                this.record_unported("boolean-type", t.flags)
                return null
            }"""
new = """            if (t.flags & TypeFlagsBooleanLiteral) <> 0
            {
                ; c.booleanType — see the header.
                this.record_unported("boolean-type", t.flags)
                return null
            }
            if (t.flags & TypeFlagsEnumLike) <> 0
            {
                this.record_unported("get-base-type-of-enum-like-type", t.flags)
                return null
            }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The JS-FILE GUARD on the implicit-any block dropped, so a TypeScript declaration
# gets the JavaScript treatment. PREDICTION: a diagcheck number — the block's
# first arm is a REPORT (reportImplicitAny), so dropping the guard invents
# TS7005/7008 lines on every TypeScript declaration whose widened type is
# implicitNeverType. If nothing moves, the arm has no input in either language and
# that is the finding.
old = """        if Parser.is_in_js_file(declaration)
        {
            if this.is_empty_literal_type(w)"""
new = """        if true
        {
            if this.is_empty_literal_type(w)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# isEmptyLiteralType reads the NON-STRICT arm — undefinedWideningType instead of
# implicitNeverType. strictNullChecks is TRUE under this harness, so this is the
# option read the wrong way round, and undefinedWideningType is a type this port
# DOES answer (`case ast.KindOmittedExpression`). PREDICTION: a diagcheck number
# on any JavaScript unit with an omitted-expression initializer; if nothing moves,
# the population is empty and the transcription of the dead arm is free.
old = """        if Checker.strict_null_checks()
            return t = implicit_never_type
        t = undefined_widening_type"""
new = """        if Checker.strict_null_checks()
            return t = undefined_widening_type
        t = undefined_widening_type"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE IsImportCall FINDING, RUN BACKWARDS: the expression dispatch's
# CallExpression arm back to slice 70's KIND TEST, which sees `import("m")` and
# not `import.defer("m")`. PREDICTION: pin red on parser_import_defer_call alone —
# the two plain `import(...)` files answer the same tag either way, which is
# exactly why the defect survived a slice.
old = """            if Parser.is_import_call(node)"""
new = """            if Checker.kind_or_unknown(AstNode.expression_of(node)) = KindImportKeyword"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ast.IsImportCall's MetaProperty arm accepts any keyword, not just `import` — so
# `new.target(...)` would be read as a deferred import. PREDICTION: ungated;
# `new.target` is not callable in any corpus unit, and the conjunct is transcribed
# because its absence is invisible rather than because it fires.
old = """                if mp.keyword_token <> KindImportKeyword
                    return false
                return meta_property_name_is_defer(mp.name)"""
new = """                return meta_property_name_is_defer(mp.name)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
#
# Every patch applied to a COPY of the tree before the first build, so an anchor
# that moved is one message here rather than a red row three minutes in.
DRY=$WORK/dry
mkdir -p "$DRY"
dry_fail=0
for g in $(ls "$PATCHDIR"/*.py | sort); do
  name=$(basename "$g" .py)
  cp "$CHECKER" "$DRY/checker.scaly"
  cp "$PARSER"  "$DRY/parser.scaly"
  case "$name" in
    g27) target="$DRY/parser.scaly" ;;
    *)   target="$DRY/checker.scaly" ;;
  esac
  if ! python3 "$g" "$target" > "$DRY/log" 2>&1; then
    red "DRY RUN: $name does not apply — its anchor has moved."
    sed 's/^/    /' "$DRY/log"
    dry_fail=1
  fi
done
[ "$dry_fail" = 1 ] && exit 2
echo "dry run: all patches apply."

baseline

control "g01 the whole chapter back to a stop (the premise)"   "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the quick path never consulted"                   "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the contextual branch taken unconditionally"      "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the padding block entered and both gates forced"  "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the AWAIT arm dropped"                            "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the AWAIT arm reports without the operand test"   "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the CALL arm dropped"                             "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the call arm's super conjunct dropped"            "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the call arm's require conjunct dropped"          "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the call arm's import conjunct dropped"           "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the Symbol term never undecidable"                "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the Symbol.for property-access rewrite dropped"   "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the NEW arm dropped"                              "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the ASSERTION arm dropped"                        "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the const-type-reference exclusion dropped"       "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the literal arm reads expr instead of node"       "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the literal arm's boolean pair dropped"           "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the widening skipped altogether"                  "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the const/readonly short-circuit dropped"         "$CHECKER" "$PATCHDIR/g19.py"
control "g20 only the readonly half dropped"                   "$CHECKER" "$PATCHDIR/g20.py"
control "g21 isFreshLiteralType always true"                   "$CHECKER" "$PATCHDIR/g21.py"
control "g22 isFreshLiteralType always false"                  "$CHECKER" "$PATCHDIR/g22.py"
control "g23 the widening arms' order changed"                 "$CHECKER" "$PATCHDIR/g23.py"
control "g24 the JS-file guard on the implicit-any block"      "$CHECKER" "$PATCHDIR/g24.py"
control "g25 isEmptyLiteralType reads the non-strict arm"      "$CHECKER" "$PATCHDIR/g25.py"
control "g26 the dispatch's import fork back to a kind test"   "$CHECKER" "$PATCHDIR/g26.py"
control "g27 IsImportCall's MetaProperty keyword conjunct"     "$PARSER"  "$PATCHDIR/g27.py"

echo
echo "################################################################"
bold "DONE — 27 rows."
echo "A row that is UNGATED on both instruments needs an argument,"
echo "not a shrug."
