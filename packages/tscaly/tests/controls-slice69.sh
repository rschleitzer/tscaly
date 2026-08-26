#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# controls-slice69.sh — the slice-69 battery: THE TYPE OF A VARIABLE, A PARAMETER
# OR A PROPERTY. getTypeOfVariableOrParameterOrProperty and its worker,
# getTypeForVariableLikeDeclaration, widenTypeForVariableLikeDeclaration,
# reportImplicitAny, getTypeFromTypeNode's keyword arms,
# getConditionalFlowTypeOfType, the unported MARK — and, in a second file, the
# parser's CheckJsDirective, which this slice is the reader of.
#
# ★★★ DIAGCHECK IS THE POSITIVE INSTRUMENT, and more sharply than in slice 68: the
# implicit-any family (TS7005/7006/7008) is this slice's whole product, so most
# rows below go red by INVENTING a line — the failure the subsequence relation is
# built to catch. The PIN carries the other half, the tags of the stops.
#
# ★★★ TWO ROWS ARE THE DEFECTS THIS SLICE HAD TO BUILD BEFORE THEY WERE RIGHT, and
# they pull in opposite directions. g24 puts back the FLAG comparison the first
# draft used and 377 units go red — a nil from getTypeForVariableLikeDeclaration
# means both *nothing can be inferred* and *this call stopped*, and once anything
# in the file has reported the flag can no longer tell them apart. g25 puts back
# the ABSOLUTE test the draft before that used and the numbers collapse instead:
# every declaration after a file's first report becomes a silent no-op. Only the
# monotone report COUNT answers both, and the pair is the proof.
#
# ★★ g14 IS THE OTHER MEASURED MISTAKE. The parameter arm's four questions all
# answer nothing at a SYNTACTIC test, so the reference falls through them to
# `return nil` and the widener reports; a stop covering the block whole — the first
# draft — takes 26 of the corpus's TS7006 with it. A lost line is a subsequence of
# anything, so the row is ungated and the NUMBER is its whole content.
#
# ★★★ ITERATE AT STAGE 1 AND CONFIRM AT STAGE 2 ONCE — slice 64's rule.
#
# Usage (nothing may edit the tree while this runs — §3.5y):
#
#   packages/tscaly/tests/run.sh                      # stage 1, ~25 s
#   packages/tscaly/tests/controls-slice69.sh 2>&1 | tee /tmp/battery69.log
#   TSCALY_STAGE=2 packages/tscaly/tests/run.sh       # ~7 min, ONCE
#   packages/tscaly/tests/controls-slice69.sh 2>&1 | tee /tmp/battery69-s2.log

set -u
cd "$(dirname "$0")/../../.."
REPO=$(pwd)

DIAGCHECK=packages/tscaly/tests/diagcheck.sh
PKG=packages/tscaly
CHECKER=$PKG/0.1.0/tscaly/checker.scaly
PARSER=$PKG/0.1.0/tscaly/parser.scaly
FIX=$PKG/tests/fixtures

LIBSCALY=${LIBSCALY:-/tmp/libscaly.a}
SCALYC=${SCALYC:-$REPO/scalyc/build/scalyc}

# The fixtures the PIN reads. Most of them share `check-expression` on the
# unpatched tree, which is the point: what they pin is that a row does not push a
# unit into a DIFFERENT hole, and the four that already differ (the optional
# property, the rest parameter, the mark file and the body walk) are the rows'
# real targets.
TAGFILES="
$FIX/checker_implicit_any_variable.ts
$FIX/checker_implicit_any_parameter.ts
$FIX/checker_implicit_any_member.ts
$FIX/checker_implicit_any_report_mark.ts
$FIX/checker_implicit_any_rest_param.ts
$FIX/checker_annotated_keyword_type.ts
$FIX/checker_optional_property_type.ts
$FIX/checker_implicit_any_js_check.js
$FIX/checker_implicit_any_js_plain.js
$FIX/checker_implicit_any_js_nocheck.js
$FIX/checker_implicit_any_js_last_wins.js
$FIX/checker_function_body_walk.ts
$FIX/checker_overload_signatures_stop.ts
"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

if [ ! -d "$PKG/tests/out/cases" ]; then
  red "no artifact tree at $PKG/tests/out/cases — run tests/run.sh first."
  echo "Both instruments compare against the reference dumps that run produced."
  exit 2
fi

WORK=$(mktemp -d -t tscaly-ctl69)

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

build_diag_bin() {
  "$SCALYC" -c --no-prelude -o "$WORK/pkg.o" "$PKG/0.1.0/tscaly.scaly" > "$WORK/build.log" 2>&1 || return 1
  "$SCALYC" -c -o "$WORK/types.o" "$PKG/0.1.0/tscaly_types.scaly" >> "$WORK/build.log" 2>&1 || return 1
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
  bold "BASELINE — both instruments"
  if ! build_diag_bin; then
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
  if ! build_diag_bin; then
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
    echo "  pin       unmoved — all thirteen fixtures answer the same tag."
  else
    green "pin       RED"
    diff "$WORK/base.tags" "$WORK/ctl.tags" | sed 's/^/    /'
  fi
  if [ "$rc" = 0 ] && cmp -s "$WORK/base.tags" "$WORK/ctl.tags"; then
    if [ "$speaking" != "$DIAG_LINES" ] || [ "$diags" != "$DIAG_DIAGS" ]; then
      echo "  ungated on both, WITH A NUMBER: $DIAG_LINES/$DIAG_DIAGS -> $speaking/$diags."
    else
      red "UNGATED on BOTH INSTRUMENTS AND NOTHING MOVED AT ALL."
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
# ★★ THE valueSymbolLinks MEMO MADE TO MISS ALWAYS — every ask recomputes.
# PREDICTION: red by DUPLICATION wherever one symbol's type is asked twice, which
# is the shape check_parameter's rest-param branch makes.
old = """        let links this.value_symbol_link_of(symbol)
        if links.resolved_type = null
        {
            let t this.get_type_of_variable_or_parameter_or_property_worker(symbol)"""
new = """        let links this.value_symbol_link_of(symbol)
        if true
        {
            let t this.get_type_of_variable_or_parameter_or_property_worker(symbol)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g02.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE MEMO WRITE DROPPED — the answer is computed and never remembered. The
# same duplication as g01 from the other side, and the pair is what says the memo
# is semantics rather than speed here.
old = """                if sensitive = false
                    set links.resolved_type: t"""
new = """                if false
                    set links.resolved_type: t"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g03.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ isParameterOfContextSensitiveSignature FORCED TRUE — nothing is ever
# memoised. PREDICTION: identical to g02, because the guard's only effect is to
# withhold the write. It exists to price the guard rather than the memo.
old = """        if AstNode.kind_of(decl) <> KindParameter
            return false
        let fn AstNode.parent_node_of(decl)"""
new = """        if AstNode.kind_of(decl) <> KindParameter
            return true
        let fn AstNode.parent_node_of(decl)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g04.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE PROTOTYPE ARM REMOVED — a `X.prototype` symbol falls into the ordinary
# variable path. Whether this corpus binds one at all is the row's question.
old = """        if (f & SymbolFlagsPrototype) <> 0
        {"""
new = """        if false
        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g05.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE RESOLUTION PUSH MADE TO FAIL ALWAYS — every variable's type is a
# circularity. PREDICTION: the widest red in the battery, because
# reportCircularityError's second report is TS7022 and its first is TS2502, and
# neither is in the reference's list for an ordinary declaration.
old = """        if this.push_type_resolution(symbol, null, TypeSystemPropertyNameType) = false
            return this.report_circularity_error(symbol)"""
new = """        if true
            return this.report_circularity_error(symbol)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g06.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE POP MADE TO FAIL ALWAYS — the same reports through the other exit, and
# the pair says the two exits are distinct code rather than one guard written
# twice.
old = """        if this.pop_type_resolution() = false
            return this.report_circularity_error(symbol)
        result"""
new = """        if true
            return this.report_circularity_error(symbol)
        result"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g07.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE FIVE-KIND FILTER EMPTIED — every declaration takes the "remaining arms"
# report instead of the variable-like path. PREDICTION: the PIN goes red across
# the board and diagcheck loses every implicit-any line; it is the crudest row and
# it is here to say the path is REACHED at all.
old = """        if variable_like = false
        {"""
new = """        if true
        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g08.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE for-in / for-of GRANDPARENT ARMS DROPPED. A `for (const k in o)`
# declaration then has no annotation and no initializer, so it falls through to
# `return nil` and the widener invents a TS7005 the reference does not have.
old = """            if gk = KindForInStatement
            {
                this.record_unported("get-index-type", gk)
                return null
            }
            if gk = KindForOfStatement
            {
                this.record_unported("check-right-hand-side-of-for-of", gk)
                return null
            }"""
new = """            if false
            {
                this.record_unported("get-index-type", gk)
                return null
            }
            if false
            {
                this.record_unported("check-right-hand-side-of-for-of", gk)
                return null
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g09.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE BINDING-ELEMENT ARM DROPPED. The element then falls through to `return
# nil` and reports TS7031 — which the reference ALSO reports for a binding pattern
# with no type. So the row's question is whether the two agree by accident, and
# the answer is what makes the arm a stop rather than a fallthrough.
old = """            if dk = KindBindingElement
            {
                this.record_unported("get-type-for-binding-element-parent", dk)
                return null
            }"""
new = """            if false
            {
                this.record_unported("get-type-for-binding-element-parent", dk)
                return null
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g10.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE ANNOTATED FORK REMOVED — an annotation is computed and then ignored, so
# every annotated declaration falls to the un-annotated path and invents an
# implicit-any report.
old = """        if declared_type <> null
            return this.add_optionality_ex(declared_type as ref[Type], is_property, is_optional)"""
new = """        if false
            return this.add_optionality_ex(declared_type as ref[Type], is_property, is_optional)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g11.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE OPTIONAL HALF REMOVED — `x?: string` answers `string` instead of
# stopping. PREDICTION: the PIN goes red on checker_optional_property_type.ts and
# diagcheck cannot see it, because the type a stop protects is invisible to the C
# section. It is the clearest row for what the two instruments each own.
old = """        if Checker.strict_null_checks()
        {
            if is_optional
            {"""
new = """        if Checker.strict_null_checks()
        {
            if false
            {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g12.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ include_optionality IGNORED — is_optional is never computed. The same red as
# g11 through the other term, and the pair separates the OPTION from the QUESTION.
old = """        var is_optional false
        if include_optionality
            set is_optional: Checker.is_optional_declaration(declaration)"""
new = """        var is_optional false
        if false
            set is_optional: Checker.is_optional_declaration(declaration)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g13.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE CATCH-CLAUSE ARM DROPPED. `catch (e)` then takes the autoType path and
# `catch (e: string)` answers `string` rather than errorType — both of them types
# no instrument here can see. PREDICTION: ungated, and the row exists to say so
# with a number rather than to leave the arm unmeasured.
old = """        if Checker.is_catch_clause_variable_declaration_or_binding_element(declaration)
        {"""
new = """        if false
        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g14.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PARAMETER ARM TURNED BACK INTO A STOP — the first draft of this slice.
# PREDICTION: ungated, WITH A NUMBER, and the number is the whole content: a lost
# line is a subsequence of anything, so diagcheck cannot go red on it, and what
# disappears is 26 of the corpus's TS7006.
old = """            let fk AstNode.kind_of(fn)
            ; "For a parameter of a set accessor, use the type of the get accessor"""
new = """            let fk AstNode.kind_of(fn)
            this.record_unported("get-contextually-typed-parameter-type", dk)
            return null
            ; "For a parameter of a set accessor, use the type of the get accessor"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g15.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE INITIALIZER ARM DROPPED — `const c = 1` falls through to `return nil` and
# invents a TS7005. It is the same shape g24 produces by accident, reached on
# purpose.
old = """        if AstNode.initializer_of(declaration) <> null
        {
            this.record_unported("check-declaration-initializer", dk)
            return null
        }"""
new = """        if false
        {
            this.record_unported("check-declaration-initializer", dk)
            return null
        }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g16.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE noImplicitAny autoType ARM REMOVED — a plain `var p;` then reports TS7005
# where the reference is silent, which is exactly the negative half of
# checker_implicit_any_variable.ts.
old = """                    let initializer AstNode.initializer_of(declaration)
                    if (Binder.combined_node_flags(declaration) & NodeFlagsConstant) = 0"""
new = """                    let initializer AstNode.initializer_of(declaration)
                    if false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g17.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE anyArrayType STOP REMOVED — a rest parameter answers plain `any` and
# reports. ★★★The interesting half is that the DIAGNOSTIC would then be RIGHT
# (reportImplicitAny's dotdotdot arm is TS7019, the reference's own code) and only
# the TYPE would be wrong, which the C section cannot see. So the row is expected
# to move diagcheck's count UPWARD while making the port less faithful — the one
# shape in this battery where a green instrument argues for the wrong code.
old = """                ; anyArrayType — createArrayType over the global Array again.
                this.record_unported("any-array-type", KindParameter)
                return null"""
new = """                let unused 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g18.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ THE WIDENER'S THREE GUARDS ON THE NON-NIL SIDE REMOVED. Each stands behind a
# flag no type this slice can make carries, so PREDICTION: ungated, and the row is
# here to hold the claim rather than to find something.
old = """            if (ty.flags & TypeFlagsESSymbol) <> 0
            {"""
new = """            if true
            {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g19.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ reportErrors FORCED FALSE at the widener — every implicit-any report is lost
# and nothing else changes. Ungated by construction (a lost line is a subsequence)
# and the NUMBER is the price of the whole family.
old = """        if report_errors
        {
            if this.declaration_belongs_to_private_ambient_member(declaration) = false"""
new = """        if false
        {
            if this.declaration_belongs_to_private_ambient_member(declaration) = false"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g20.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE PRIVATE-AMBIENT EXEMPTION DROPPED — `declare class C { private x; }` then
# reports. Whether the corpus contains a private member of an ambient declaration
# that this port's walk REACHES is the row's question, and the class-member walk
# is what stands in front of it.
old = """            if this.declaration_belongs_to_private_ambient_member(declaration) = false
                this.report_implicit_any(declaration, any_type, WideningKindNormal)"""
new = """            this.report_implicit_any(declaration, any_type, WideningKindNormal)"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g21.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE JAVASCRIPT GUARD IN reportImplicitAny DROPPED — every JS unit reports.
# 151 of the corpus's units are JavaScript or JSX and checkJs is off for all of
# them, so this is the widest invented-line row there is.
old = """        if Parser.is_in_js_file(declaration)
        {"""
new = """        if false
        {"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g22.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE REST-PARAMETER CODE AND THE PLAIN ONE SWAPPED — TS7019 where TS7006
# belongs. The span is identical, so the row measures the CODE alone, which is
# what diagcheck compares beside the two offsets.
old = """            if AstNode.dot_dot_dot_token_of(declaration) <> null
                set code: DiagRest_parameter_0_implicitly_has_an_any_type
            else
                set code: DiagParameter_0_implicitly_has_an_1_type"""
new = """            set code: DiagRest_parameter_0_implicitly_has_an_any_type"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g23.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE TS7051 STOP REMOVED — a parameter of a call signature, a method signature
# or a function type whose name reads as a TYPE reports TS7006 where the reference
# reports TS7051. It is the one place in this slice where a resolveName decides
# WHICH code, not whether one comes out.
old = """                        this.record_unported("resolve-name", KindParameter)
                        return"""
new = """                        let unused 0"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g24.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE UNPORTED *MARK* REPLACED BY THE FLAG — the second draft of this slice.
# getTypeForVariableLikeDeclaration's nil means both "nothing can be inferred" and
# "this call stopped", and once anything in the file has reported, the flag cannot
# tell them apart: every declaration after the first stop invents an implicit-any.
old = """        let mark this.unported_mark()
        let t this.get_type_for_variable_like_declaration(declaration, true)
        if this.unported_mark() <> mark
            return null"""
new = """        let mark this.is_unported()
        let t this.get_type_for_variable_like_declaration(declaration, true)
        if this.is_unported() <> mark
            return null"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g25.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE MARK REPLACED BY AN ABSOLUTE TEST — the FIRST draft. The failure is the
# opposite of g24's: every declaration after a file's first report becomes a silent
# no-op, so nothing is invented and the count collapses. The pair is the proof that
# only a monotone count answers both questions.
old = """        let mark this.unported_mark()
        let t this.get_type_for_variable_like_declaration(declaration, true)
        if this.unported_mark() <> mark
            return null"""
new = """        let t this.get_type_for_variable_like_declaration(declaration, true)
        if this.is_unported()
            return null"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g26.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE KEYWORD ARMS OF getTypeFromTypeNodeWorker REMOVED — every annotation
# reports again, which is where slice 68 left the tree. PREDICTION: the PIN goes
# red on checker_annotated_keyword_type.ts and diagcheck loses lines; the two
# together are the whole of what the annotated fork buys.
old = """        if k = KindStringKeyword
            return string_type"""
new = """        if false
            return string_type"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g27.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★ getConditionalFlowTypeOfType's WALK CUT AT ITS FIRST STEP — the substitution
# walk never climbs. Its only effect is the constraint list, and no type this slice
# makes is a type variable, so PREDICTION: ungated. The row prices the walk rather
# than finding a defect in it.
old = """            if Checker.is_statement(cur)
                return t"""
new = """            if true
                return t"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g28.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★ THE SUBSTITUTION REPORT REMOVED — a type annotation in the TRUE branch of a
# conditional type answers `t` instead of stopping. It is the other end of g27: if
# both are ungated, no input reaches the append at all, and that is the walk's
# whole unreachability claim.
old = """            if substitutes
            {
                this.record_unported("get-implied-constraint", pk)
                return null
            }"""
new = """            if false
            {
                this.record_unported("get-implied-constraint", pk)
                return null
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g29.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE PARSER'S CheckJsDirective NEVER WRITTEN — the field the parser used to
# drop, dropped again. PREDICTION: ungated WITH A NUMBER, because what disappears
# is the `@ts-check` fixture's TS7006 and a lost line is a subsequence of anything.
# Read with g30, which breaks the same field in the direction diagcheck CAN see.
old = """            if found <> CheckJsDirectiveNone
                set check_js_directive: found"""
new = """            if false
                set check_js_directive: found"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g30.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ THE DIRECTIVE READ AS ENABLED WHENEVER IT IS PRESENT — `@ts-nocheck` becomes
# `@ts-check`. This is the tristate collapsed to a boolean, and it is the row that
# says the third state is load-bearing rather than tidy (§3.5j).
old = """            if this.pragma_name_is(pos + 1, name_end, "ts-nocheck")
                set found: CheckJsDirectiveDisabled"""
new = """            if this.pragma_name_is(pos + 1, name_end, "ts-nocheck")
                set found: CheckJsDirectiveEnabled"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

cat > "$PATCHDIR/g31.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
# ★★★ LAST-WINS MADE FIRST-WINS — the false friend this slice walked into. The
# reference's own arm builds its Pragma with no TextRange, which reads like a zero
# value and would make the FIRST directive stick; `Pragma` embeds `CommentRange`
# embeds `core.TextRange`, so it is the comment's range, promoted. Only
# checker_implicit_any_js_last_wins.js can tell the two rules apart.
old = """            if found <> CheckJsDirectiveNone
                set check_js_directive: found"""
new = """            if found <> CheckJsDirectiveNone
            {
                if check_js_directive = CheckJsDirectiveNone
                    set check_js_directive: found
            }"""
assert s.count(old) == 1, s.count(old)
open(p, "w").write(s.replace(old, new))
PY

DRY=$WORK/dry
mkdir -p "$DRY"
dry_ok=1
dry_one() {   # $1 = id, $2 = file
  local id=$1 f=$2
  cp "$f" "$DRY/copy"
  if python3 "$PATCHDIR/$id.py" "$DRY/copy" 2> "$DRY/err"; then
    printf '  %s  ok   (%s)\n' "$id" "$(basename "$f")"
  else
    red "  $id  DID NOT APPLY — $(tail -1 "$DRY/err")"
    dry_ok=0
  fi
}
echo "################################################################"
bold "DRY RUN — every patch against a copy, before a single build"
for id in g01 g02 g03 g04 g05 g06 g07 g08 g09 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24 g25 g26 g27 g28; do
  dry_one "$id" "$CHECKER"
done
for id in g29 g30 g31; do
  dry_one "$id" "$PARSER"
done
if [ "$dry_ok" != 1 ]; then
  red "at least one anchor is wrong. Fix them before spending the battery."
  exit 2
fi

baseline

control "g01 the valueSymbolLinks memo made to miss always"        "$CHECKER" "$PATCHDIR/g01.py"
control "g02 the memo write dropped"                               "$CHECKER" "$PATCHDIR/g02.py"
control "g03 isParameterOfContextSensitiveSignature forced true"   "$CHECKER" "$PATCHDIR/g03.py"
control "g04 the prototype arm removed"                            "$CHECKER" "$PATCHDIR/g04.py"
control "g05 the resolution push made to fail always"              "$CHECKER" "$PATCHDIR/g05.py"
control "g06 the pop made to fail always"                          "$CHECKER" "$PATCHDIR/g06.py"
control "g07 the five-kind filter emptied"                         "$CHECKER" "$PATCHDIR/g07.py"
control "g08 the for-in / for-of grandparent arms dropped"         "$CHECKER" "$PATCHDIR/g08.py"
control "g09 the binding-element arm dropped"                      "$CHECKER" "$PATCHDIR/g09.py"
control "g10 the annotated fork removed"                           "$CHECKER" "$PATCHDIR/g10.py"
control "g11 the optional half removed"                            "$CHECKER" "$PATCHDIR/g11.py"
control "g12 include_optionality ignored"                          "$CHECKER" "$PATCHDIR/g12.py"
control "g13 the catch-clause arm dropped"                         "$CHECKER" "$PATCHDIR/g13.py"
control "g14 the parameter arm turned back into a stop"            "$CHECKER" "$PATCHDIR/g14.py"
control "g15 the initializer arm dropped"                          "$CHECKER" "$PATCHDIR/g15.py"
control "g16 the noImplicitAny autoType arm removed"               "$CHECKER" "$PATCHDIR/g16.py"
control "g17 the anyArrayType stop removed"                        "$CHECKER" "$PATCHDIR/g17.py"
control "g18 the widener's three non-nil guards removed"           "$CHECKER" "$PATCHDIR/g18.py"
control "g19 reportErrors forced false at the widener"             "$CHECKER" "$PATCHDIR/g19.py"
control "g20 the private-ambient exemption dropped"                "$CHECKER" "$PATCHDIR/g20.py"
control "g21 the JavaScript guard in reportImplicitAny dropped"    "$CHECKER" "$PATCHDIR/g21.py"
control "g22 the rest-parameter code used for every parameter"     "$CHECKER" "$PATCHDIR/g22.py"
control "g23 the TS7051 stop removed"                              "$CHECKER" "$PATCHDIR/g23.py"
control "g24 the unported MARK replaced by the FLAG"               "$CHECKER" "$PATCHDIR/g24.py"
control "g25 the mark replaced by an absolute test"                "$CHECKER" "$PATCHDIR/g25.py"
control "g26 the keyword arms of getTypeFromTypeNodeWorker removed" "$CHECKER" "$PATCHDIR/g26.py"
control "g27 getConditionalFlowTypeOfType's walk cut at step one"  "$CHECKER" "$PATCHDIR/g27.py"
control "g28 the substitution report removed"                      "$CHECKER" "$PATCHDIR/g28.py"
control "g29 the parser's CheckJsDirective never written"          "$PARSER"  "$PATCHDIR/g29.py"
control "g30 the directive read as ENABLED whenever present"       "$PARSER"  "$PATCHDIR/g30.py"
control "g31 last-wins made first-wins"                            "$PARSER"  "$PATCHDIR/g31.py"

echo
echo "################################################################"
bold "RESTORED — checker.scaly and parser.scaly, byte-identical"
git -C "$REPO" diff --stat -- "$CHECKER" "$PARSER" | tail -3
