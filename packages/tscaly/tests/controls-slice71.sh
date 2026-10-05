#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice71.sh — the slice-71 battery: THE LITERAL TYPES.
# newLiteralType and the value payload, the fresh/regular pair, the three intern
# tables, the eagerly built boolean pair, the five arms of checkExpressionWorker
# that answer a literal type, type_to_string widened to a BUILDER with four
# composing arms, and the two conversions underneath the bigint (the scanner's
# own and the checker's).
#
# ★★★ THIS BATTERY HAS THREE INSTRUMENTS AND THE THIRD IS THE SLICE'S WHOLE
# POINT. The pin over fixture TAGS sees whether an arm ANSWERS; diagcheck sees a
# diagnostic invented or lost; and neither can see the NAME a literal type gets,
# because the checker yardstick's T section is written only for a node the kind
# INVENTORY admits and getTypeOfNode answers an expression through
# `IsExpressionNode -> getRegularTypeOfExpression`, neither of which is ported.
# So tests/litcheck.sh is the third instrument, and the nine rows aimed at it are
# the only measurement the composing half of this slice has.
#
# ★★ THE LITCHECK ROWS REUSE ONE CORPUS AND ONE REFERENCE ANSWER, generated at
# BASELINE by calling litcheck.sh once. A row then rebuilds our side only and
# diffs against that stored answer — the reference cannot move, so re-deriving it
# per row would be 21 oracle builds measuring nothing.
#
# ★★ SIX ROWS ARE UNGATED ON EVERY INSTRUMENT AND EACH CARRIES ITS ARGUMENT: the
# interning (nothing compares type identity yet), the fresh/regular mint (nothing
# asks whether a type is fresh), newLiteralType's regular link (the same slot),
# the second string-literal LABEL (the switch's default answers errorType, so
# dropping a label is invisible until a T line can carry a name), the true/false
# SWAP (the same reason) — and g22, which is the only one of the six whose silence
# is a POSITIVE result rather than a limit of the instruments.
#
# ★★★ TWO PREDICTIONS IN THE FIRST RUN WERE WRONG AND BOTH BECAME FINDINGS. g13
# broke the reference's supplementary-plane arm and came back green, because that
# arm cannot be reached under this slice's narrowing — the arm is gone and the row
# now breaks the narrowing instead. g17 dropped the bigint leading-zero trim and
# came back green, because ParsePseudoBigInt's own output already carries no
# leading zero except the single `0` of zero itself, and that one prints `0n`
# through the other branch — which is what g22 was added to state.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule. The
# recorded verdicts below are stage 1's.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice71.sh 2>&1 | tee /tmp/battery71.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
LITCHECK=packages/tscaly/tests/litcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
SCANNER=$PKG/0.1.0/tscaly/scanner.scaly
JSNUM=$PKG/0.1.0/tscaly/jsnum.scaly
FIX=$PKG/tests/fixtures
LITOUT=$PKG/tests/out/lits

. packages/tscaly/tests/toolchain.sh || exit 2

# The fixtures the PIN reads — this slice's three, the two slice-70 grammar files
# whose tag it moved, the two older files whose tag is a numeric literal's, and
# ONE control that holds no literal at all and must never move.
TAGFILES="
$FIX/checker_expression_string_literal.ts
$FIX/checker_expression_boolean_literal.ts
$FIX/checker_expression_bigint_bases.ts
$FIX/checker_expression_bigint_grammar.ts
$FIX/checker_expression_numeric_grammar.ts
$FIX/checker_enum_member_walk.ts
$FIX/checker_statement_switch_duplicate_default.ts
$FIX/checker_expression_null_statement.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl71)

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
  clang -o "$WORK/tscaly_types" "$WORK/types.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/lits.o" "$PKG/0.1.0/tscaly_lits.scaly" >> "$WORK/build.log" 2>&1 || return 1
  clang -o "$WORK/tscaly_lits" "$WORK/lits.o" "$WORK/pkg.o" "$LIBSCALY" -lm >> "$WORK/build.log" 2>&1
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
LIT_CASES=""

baseline() {
  echo "################################################################"
  bold "BASELINE — three instruments"

  # The literal instrument's corpus and REFERENCE answer, made once. litcheck.sh
  # also proves the unpatched tree agrees with it, which is the precondition
  # every row below needs.
  if ! "$LITCHECK" > "$WORK/base.lit" 2>&1; then
    red "litcheck is already red on the unpatched tree — fix that first."
    sed 's/^/    /' "$WORK/base.lit"
    exit 2
  fi
  sed 's/^/  /' "$WORK/base.lit"
  LIT_CASES=$(wc -l < "$LITOUT/corpus" | tr -d ' ')
  cp "$LITOUT/ref" "$WORK/lit.ref"

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
  echo "  BASELINE   $DIAG_BASE units consistent, $DIAG_LINES speaking, $DIAG_DIAGS diagnostics;"
  echo "             litcheck $LIT_CASES inputs identical"
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
  "$WORK/tscaly_lits" "$LITOUT/corpus" > "$WORK/ctl.lit" 2>/dev/null
  local litrc=0
  cmp -s "$WORK/lit.ref" "$WORK/ctl.lit" || litrc=1
  local litdiff=0
  [ "$litrc" = 1 ] && litdiff=$(diff "$WORK/lit.ref" "$WORK/ctl.lit" | grep -c '^<')
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
  if [ "$litrc" != 0 ]; then
    green "litcheck  RED $litdiff of $LIT_CASES"
  else
    echo "  litcheck  ungated — all $LIT_CASES inputs still identical."
  fi
  if cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    echo "  pin       unmoved — all eight fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && [ "$litrc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on all three, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED ON ALL THREE INSTRUMENTS AND NOTHING MOVED AT ALL."
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
# ★★★ THE PREMISE ROW: every literal arm turned back into the stop it was through
# slice 70. PREDICTION: the pin goes red on all seven literal fixtures and NOT on
# checker_expression_null_statement, which is what proves the pin is measuring
# these arms and not something the corpus does around them.
old = """        if k = KindStringLiteral
            return this.string_literal_arm(node)"""
new = """        if k = KindStringLiteral
        {
            this.record_unported("get-string-literal-type", k)
            return null
        }
        if false
            return this.string_literal_arm(node)"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """        if k = KindNoSubstitutionTemplateLiteral
            return this.string_literal_arm(node)"""
new = """        if k = KindNoSubstitutionTemplateLiteral
        {
            this.record_unported("get-string-literal-type", k)
            return null
        }"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """            let bits jsnum_from_string(AstNode.literal_text_of(node), AstNode.literal_text_length_of(node))
            return this.get_fresh_type_of_literal_type(this.get_number_literal_type(bits))"""
new = """            this.record_unported("get-number-literal-type", k)
            return null"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """            return this.bigint_literal_arm(node)"""
new = """            this.record_unported("get-bigint-literal-type", k)
            return null"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """        if k = KindTrueKeyword
            return true_type
        if k = KindFalseKeyword
            return false_type"""
new = """        if k = KindTrueKeyword
        {
            this.record_unported("boolean-literal-type", k)
            return null
        }
        if k = KindFalseKeyword
        {
            this.record_unported("boolean-literal-type", k)
            return null
        }"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
open(p, "w").write(s)
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The STRING arm alone turned back into a stop.
# PREDICTION: pin red on checker_expression_string_literal and on nothing else.
old = """        if k = KindStringLiteral
            return this.string_literal_arm(node)"""
new = """        if k = KindStringLiteral
        {
            this.record_unported("get-string-literal-type", k)
            return null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The SECOND string-literal label dropped, so a NoSubstitutionTemplateLiteral
# falls through to the switch's DEFAULT.
# PREDICTION: UNGATED, and the reason is the default: it answers errorType, so the
# unit still completes and the tag does not move. What changes is the type — `any`
# where the reference has `` `x` `` — and no instrument here can see a type. The
# reader that would is the T section, i.e. getTypeOfNode's expression arm.
old = """        if k = KindNoSubstitutionTemplateLiteral
            return this.string_literal_arm(node)
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The NUMERIC arm turned back into a stop.
# PREDICTION: pin red on the three fixtures whose first report is a numeric
# literal — the grammar file, the enum member walk and the switch subject.
old = """            let bits jsnum_from_string(AstNode.literal_text_of(node), AstNode.literal_text_length_of(node))
            return this.get_fresh_type_of_literal_type(this.get_number_literal_type(bits))"""
new = """            this.record_unported("get-number-literal-type", k)
            return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The BIGINT arm turned back into a stop.
# PREDICTION: pin red on the two bigint fixtures and on nothing else.
old = """            return this.bigint_literal_arm(node)"""
new = """            this.record_unported("get-bigint-literal-type", k)
            return null"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The BOOLEAN arms turned back into a stop.
# PREDICTION: pin red on checker_expression_boolean_literal alone.
old = """        if k = KindTrueKeyword
            return true_type
        if k = KindFalseKeyword
            return false_type"""
new = """        if k = KindTrueKeyword
        {
            this.record_unported("boolean-literal-type", k)
            return null
        }
        if k = KindFalseKeyword
        {
            this.record_unported("boolean-literal-type", k)
            return null
        }"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# `true` answers falseType and `false` answers trueType.
# PREDICTION: UNGATED on all three. Both answers are a type, so the unit completes
# either way; the two names differ and no instrument can read one. This is the
# clearest statement the battery can make about what the T section costs — see
# g03, which is the same hole from the other side.
old = """        if k = KindTrueKeyword
            return true_type
        if k = KindFalseKeyword
            return false_type"""
new = """        if k = KindTrueKeyword
            return false_type
        if k = KindFalseKeyword
            return true_type"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# getFreshTypeOfLiteralType never mints a fresh type — every arm answers the
# REGULAR one.
# PREDICTION: UNGATED. Freshness is read by getWidenedLiteralType and by
# isFreshLiteralType, and neither is ported; the two boolean pairs are built by
# hand and are unaffected. The slot is written here and its readers are named in
# LiteralTypeData's own note, which is what this row measures the truth of.
old = """        if (t.flags & TypeFlagsFreshable) = 0
            return t
        let cached"""
new = """        if (t.flags & TypeFlagsFreshable) = 0
            return t
        if true
            return t
        let cached"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The three intern tables never hit: every occurrence of a value mints a new type.
# PREDICTION: UNGATED. Interning buys IDENTITY, and the first thing that compares
# two types by pointer is isTypeIdenticalTo. Written down at the tables' own note;
# this row is what makes that sentence a measurement rather than a claim.
for name in ("string_literal_types", "number_literal_types", "bigint_literal_types"):
    old = "        let len %s.get_length() as int\n        var i 0\n" % name
    new = "        let len 0\n        var i 0\n"
    assert s.count(old) == 1, name
    s = s.replace(old, new, 1)
open(p, "w").write(s)
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# newLiteralType's regular_type always points at the NEW type, never at the one
# the caller passed — so a fresh boolean's regular type would be itself.
# PREDICTION: UNGATED, for g08's reason: the slot has no reader here.
old = """        if regular_type = null
            Checker.set_literal_regular_type(t, t)
        else
            Checker.set_literal_regular_type(t, regular_type)"""
new = """        Checker.set_literal_regular_type(t, t)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The escape worker's BACKSLASH arm dropped: a raw `\` is written through.
# PREDICTION: litcheck RED. The corpus carries the backslash on its own and inside
# text, so the count is the number of inputs containing one.
old = """            if ch = 0x5C
                set escape: true
            if ch = 0x22"""
new = """            if ch = 0x22"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# DecodeJSStringRune's surrogate SENTINEL arm disabled, so the ordinary UTF-8
# decoder answers RuneError for a lone surrogate.
# PREDICTION: litcheck RED — `\uD800` becomes three `�`. This is the arm that
# would have been silently wrong: Go's own utf8 decoder refuses the encoding the
# reference's own scanner writes.
old = """            if b0 = 0xED"""
new = """            if b0 = 0xEE"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The NARROWING undone: a code point above 0x7f is escaped, which is what the
# printer does WITHOUT EFNoAsciiEscaping (escapeNonAsciiString).
# PREDICTION: litcheck RED on every input carrying a non-ASCII character. This
# row replaced one that broke the reference's supplementary-plane arm and came
# back UNGATED - that arm cannot be reached under this narrowing, so the
# condition worth breaking is the narrowing itself.
old = """            if ch <= 0x1F
                set escape: true"""
new = """            if ch <= 0x1F
                set escape: true
            if ch > 0x7F
                set escape: true"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The NUL's digit lookahead dropped, so a NUL is always `\0` and never `\x00`.
# PREDICTION: litcheck RED on exactly ONE hand case, `"\0" + "7"` — the reference
# writes the hex form there to keep the result from parsing as an octal escape.
old = """                if digit
                    out.append("\\\\x00")
                else
                    out.append("\\\\0")"""
new = """                out.append("\\\\0")"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The \u escape's hex digits written LOWERCASE.
# PREDICTION: litcheck RED. encodeUtf16EscapeSequence uppercases, and this is the
# kind of difference no reasoning finds and one diff finds immediately.
old = """                out.append(((d - 10) + 0x41) as char)"""
new = """                out.append(((d - 10) + 0x61) as char)"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ParsePseudoBigInt's UPPERCASE hex digits dropped.
# PREDICTION: litcheck RED — the B rows carrying `0xFF`, and every `0x…` line of
# the random family that drew an uppercase digit, answer PANIC.
old = """        if (c >= (("A" as char) as int)) and (c <= (("F" as char) as int))
            set d: (c - (("A" as char) as int)) + 10
"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "", 1))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# NewPseudoBigInt's leading-zero trim dropped in pseudo_big_int_digits — the
# SHARED body, so the checker's arm and the instrument lose it together.
# PREDICTION: litcheck RED on the B rows with leading zeros: `0007` prints
# `0007n` instead of `7n`, and `000` prints `000n` instead of `0n`.
old = """        var i 0
        while i < m
        {
            if (*(out + i) as int) <> (("0" as char) as int)
                break
            set i: i + 1
        }
        set *out_start: i
        m - i"""
new = """        m"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# PseudoBigInt.String's EMPTY test replaced by a comparison against the digit
# `0` — the mistake a reader makes who has not read the struct's own comment.
# PREDICTION: litcheck RED on the zero rows, and the number is the finding: an
# empty Base10Value is how the reference SPELLS zero, so the two tests are not
# interchangeable even though both look like "is it zero".
old = """        if n = 0
        {
            out.append("0" as char)
            return
        }
        if negative"""
new = """        if n = 0
            return
        if negative"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# g17 AND g18 AT ONCE, and this is the row that explains why g17 alone is green.
# The two are halves of ONE decision - the reference represents the value zero as
# an EMPTY Base10Value, so the trim is what produces the empty and the length test
# is what reads it. Break either and the pair disagrees with the reference; break
# BOTH and `0n` comes out right again through the other route.
# PREDICTION: UNGATED on all three instruments, and the prediction IS the finding
# (a green suite is evidence about the PAIR, never about either
# half).
old = """        var i 0
        while i < m
        {
            if (*(out + i) as int) <> (("0" as char) as int)
                break
            set i: i + 1
        }
        set *out_start: i
        m - i"""
new = """        m"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
old = """        if n = 0
        {
            out.append("0" as char)
            return
        }
        if negative"""
new = """        if n = 0
            return
        if negative"""
assert s.count(old) == 1
s = s.replace(old, new, 1)
open(p, "w").write(s)
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# The scanner's hex LOWERCASE dropped — the state this file was in before this
# slice, under a comment that claimed the two spellings coincided.
# PREDICTION: litcheck RED on the T rows whose source carries an uppercase hex
# digit. It is the row that found the defect, run backwards.
old = """        let lower marker = (("x" as char) as int)"""
new = """        let lower false"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# set_bigint_token_value back to slice 44's STAND-IN: the raw source slice.
# PREDICTION: litcheck RED on the T rows — every bigint's value is the source text
# including the `_`, which is the defect the stand-in carried.
old = """    procedure set_bigint_token_value(this)
    {
        ; s.tokenValue += "n"
        this.append_n_to_token_value()"""
new = """    procedure set_bigint_token_value(this)
    {
        this.set_token_value_range(state.token_start, state.pos)
        if true
            return
        ; s.tokenValue += "n"
        this.append_n_to_token_value()"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# Only the BINARY/OCTAL rewrite removed from the scanner, the `+= "n"` kept.
# PREDICTION: litcheck RED on the T rows for `0b…`/`0o…` — and this row is the
# PROOF for the sentence in set_bigint_token_value's note: the CHECKER's answer is
# unaffected, because ParsePseudoBigInt is idempotent on its own output, so what
# the rewrite buys is the token value itself and nothing downstream of it.
old = """        if (state.token_flags & TokenFlagsBinaryOrOctalSpecifier) = 0
            return"""
new = """        if true
            return"""
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new, 1))
PY

# ── the dry run ─────────────────────────────────────────────────────────────
#
# Every patch applied to a COPY of the tree before the first build, so an anchor
# that moved is one message here rather than a red row twenty minutes in.
DRY=$WORK/dry
mkdir -p "$DRY"
dry_fail=0
for g in $(ls "$PATCHDIR"/*.py | sort); do
  name=$(basename "$g" .py)
  cp "$CHECKER" "$DRY/checker.scaly"
  cp "$SCANNER" "$DRY/scanner.scaly"
  cp "$JSNUM"   "$DRY/jsnum.scaly"
  case "$name" in
    g19|g20|g21) target="$DRY/scanner.scaly" ;;
    g16)         target="$DRY/jsnum.scaly" ;;
    *)           target="$DRY/checker.scaly" ;;
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

control "g01 every literal arm back to a stop (the premise)" "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the STRING arm back to a stop"                  "$CHECKER" "$PATCHDIR/g02.py"
control "g03 the second string LABEL dropped"                "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the NUMERIC arm back to a stop"                 "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the BIGINT arm back to a stop"                  "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the BOOLEAN arms back to a stop"                "$CHECKER" "$PATCHDIR/g06.py"
control "g07 true and false swapped"                         "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the fresh type never minted"                    "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the three intern tables never hit"              "$CHECKER" "$PATCHDIR/g09.py"
control "g10 newLiteralType always self-regular"             "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the escape worker's backslash arm dropped"      "$CHECKER" "$PATCHDIR/g11.py"
control "g12 the surrogate SENTINEL decoder disabled"        "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the NeverAsciiEscape narrowing undone"          "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the NUL digit lookahead dropped"                "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the \\u escape's hex written lowercase"          "$CHECKER" "$PATCHDIR/g15.py"
control "g16 ParsePseudoBigInt loses uppercase hex"          "$JSNUM"   "$PATCHDIR/g16.py"
control "g17 the bigint leading-zero trim dropped"           "$CHECKER" "$PATCHDIR/g17.py"
control "g18 PseudoBigInt.String's empty test replaced"      "$CHECKER" "$PATCHDIR/g18.py"
control "g19 the scanner's hex lowercase dropped"            "$SCANNER" "$PATCHDIR/g19.py"
control "g20 set_bigint_token_value back to the stand-in"    "$SCANNER" "$PATCHDIR/g20.py"
control "g21 only the binary/octal rewrite removed"          "$SCANNER" "$PATCHDIR/g21.py"
control "g22 g17 AND g18 together (the cancelling pair)"     "$CHECKER" "$PATCHDIR/g22.py"

echo
echo "################################################################"
bold "DONE — 22 rows."
echo "A row that is UNGATED on all three instruments needs an argument,"
echo "not a shrug."
